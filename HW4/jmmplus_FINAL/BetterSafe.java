import java.util.concurrent.atomic.AtomicIntegerArray;

class BetterSafeState implements State
{
	AtomicIntegerArray value;
	private byte maxval;
	
	public static int[] ConvertByte2IntArray(byte[] v)
	{
    		int[] temp = new int[v.length];
    		for (int i = 0; i < v.length; i++)
    		{
        		temp[i] = v[i] & 0xff;
    		}
    		return temp;
	}

	BetterSafeState(byte[] v) { 
		value = new AtomicIntegerArray(ConvertByte2IntArray(v)); 
		maxval = 127; }
	
	BetterSafeState(byte[] v, byte m) { 
		value = new AtomicIntegerArray(ConvertByte2IntArray(v)); 
		maxval = m; }	

	public int size() { return value.length(); }
	
	public byte[] current()
	{
		byte[] v = new byte[value.length()];
		for (int i = 0; i < value.length(); i++)
		{		
			v[i] = (byte)value.get(i);
		}		
		return v;
	}
	
	public boolean swap(int i, int j)
	{
		if (value.get(i) <= 0 || value.get(j) >= maxval)
		{
			return false;
		}	
		value.getAndDecrement(i);
		value.getAndIncrement(j);
		return true;
	}
}
