// Import Atomic Integer Array
import java.util.concurrent.atomic.AtomicIntegerArray;

class GetNSet implements State
{
	AtomicIntegerArray value;
	GetNSet(int[] v) { value = new AtomicIntegerArray(v); }

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

		value.set(i, value.get(i)-1); 
		value.set(j, value.get(j)+1);

		return true;
	}
}