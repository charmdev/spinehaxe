package spine;

import haxe.ds.Vector;

class ArrayUtils 
{
	public static inline function allocFloat(n:Int):Vector<Float> 
	{
		var v:Vector<Float> = new Vector(n);
		for (i in 0 ... n) v.set(i, 0);
		return v;
	}

	public static inline function allocString(n:Int):Vector<String> 
	{
		return new Vector<String>(n);
	}
}