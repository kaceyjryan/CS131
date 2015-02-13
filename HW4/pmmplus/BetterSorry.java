import java.util.concurrent.locks.ReentrantLock;

class BetterSorryState implements State
{
	private int [] value;
	ReentrantLock lock;
	// Create lock, default to unlocked.
	//AtomicBoolean lock;
	boolean locked;
	
	BetterSorryState(int[] v)
	{
		value = v;
		lock = new ReentrantLock();
	}
	
	public int size() { return value.length; }
	
	public int[] current() { return value; }
	
	public boolean swap(int i, int j)
	{
		if (value[i] <= 0)
			return false;
		lock.lock();
		try {
			value[i]--;
			value[j]++;
		} finally {
			lock.unlock();
		}
		return true;
	}
}