using SettingsSaveNow;

static void Check(bool condition, string message)
{
    if (!condition) throw new Exception(message);
}

var operation = new SaveOperation();
var started = new TaskCompletionSource();
var release = new TaskCompletionSource();
var calls = 0;
var first = operation.TryRunAsync(async () =>
{
    Interlocked.Increment(ref calls);
    started.SetResult();
    await release.Task;
});
await started.Task;
Check(operation.IsRunning && !first.IsCompleted, "The save must remain busy until completion.");
var competitors = Enumerable.Range(0, 32).Select(_ => Task.Run(() =>
    operation.TryRunAsync(() => { Interlocked.Increment(ref calls); return Task.CompletedTask; })));
Check((await Task.WhenAll(competitors)).All(ran => !ran), "Overlapping clicks must not queue another save.");
Check(calls == 1, "Only the first request may invoke the save API.");
release.SetResult();
Check(await first && !operation.IsRunning, "Successful completion must release the gate.");
Console.WriteLine("PASS: concurrent views and completion");

foreach (var asynchronous in new[] { false, true })
{
    var expected = new InvalidOperationException("Simulated storage failure");
    try
    {
        await operation.TryRunAsync(asynchronous
            ? async () => { await Task.Yield(); throw expected; }
            : () => throw expected);
        throw new Exception("Storage failures must propagate.");
    }
    catch (InvalidOperationException actual)
    {
        Check(ReferenceEquals(expected, actual), "Preserve the original storage exception.");
    }
    Check(!operation.IsRunning, "Failed saves must release the gate.");
    Check(await operation.TryRunAsync(() => Task.CompletedTask), "Retry must succeed after a failure.");
}
Console.WriteLine("PASS: synchronous/asynchronous failure and retry");

try
{
    await operation.TryRunAsync(() => Task.FromCanceled(new CancellationToken(true)));
    throw new Exception("Cancellation must propagate.");
}
catch (OperationCanceledException) { }
Check(!operation.IsRunning && await operation.TryRunAsync(() => Task.CompletedTask),
    "Cancellation must allow another save.");
Console.WriteLine("PASS: cancellation and retry");

if (args.Length > 0)
{
    using var engine = Mono.Cecil.ModuleDefinition.ReadModule(args[0]);
    var view = engine.GetType("FrooxEngine.RootCategoryView");
    Check(view != null && view.Methods.Any(method =>
        method.Name == "OnFeedGenerationFinished" && !method.IsStatic &&
        method.Parameters.Count == 0 && method.ReturnType.FullName == "System.Void"),
        "The settings-view Harmony target must exist in the selected engine assembly.");
    var manager = engine.GetType("FrooxEngine.SettingManagersManager");
    Check(manager != null && manager.Methods.Any(method =>
        method.Name == "SaveAllSettings" && !method.IsStatic &&
        method.Parameters.Count == 0 && method.ReturnType.FullName == "System.Threading.Tasks.Task"),
        "The normal settings-save API must exist in the selected engine assembly.");
    Check(manager!.Fields.Any(field => field.Name == "NeverSave" &&
        field.IsStatic && field.FieldType.FullName == "System.Boolean"),
        "The engine's no-save switch must be available.");
    Console.WriteLine("PASS: settings view/save API in " + args[0]);
}
