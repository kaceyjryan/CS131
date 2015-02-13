import java.util.concurrent.atomic.AtomicIntegerArray;

class BetterSafeState implements State
{
	AtomicIntegerArray value;
	
	BetterSafeState(int[] v) { value = new AtomicIntegerArray(v); }
	
	public int size() { return value.length(); }
	
	public int[] current()
	{
		int[] v = new int[value.length()];
		for (int i = 0; i < value.length(); i++)
			v[i] = value.get(i);
		
		return v;
	}
	
	public boolean swap(int i, int j)
	{
		if (value.get(i) <= 0)
			return false;
		
		value.getAndDecrement(i);
		value.getAndIncrement(j);
		return true;
	}
}