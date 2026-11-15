namespace SettingsSaveNow;

// Shared by every settings view so multiple facets cannot start overlapping saves.
internal sealed class SaveOperation
{
    private int _running;
    public bool IsRunning => Volatile.Read(ref _running) != 0;

    public async Task<bool> TryRunAsync(Func<Task> save)
    {
        if (Interlocked.CompareExchange(ref _running, 1, 0) != 0)
            return false;

        try
        {
            await save();
            return true;
        }
        finally
        {
            Volatile.Write(ref _running, 0);
        }
    }
}
