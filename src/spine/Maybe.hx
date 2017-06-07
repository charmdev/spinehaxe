package spine;

/**
 * ...
 * @author 
 */

/*
// null safety solution by nadako
// http://code.haxe.org/category/principles/null-safety.html
*/

abstract Maybe<T>(Null<T>) from Null<T> {

  public inline function exists():Bool {
    return this != null;
  }

  public inline function sure():T {
    return if (exists()) this else throw "No value";
  }

  public inline function or(def:T):T {
    return if (exists()) this else def;
  }

  public inline function may(fn:T->Void):Void {
    if (exists()) fn(this);
  }

  public inline function map<S>(fn:T->S):Maybe<S> {
    return if (exists()) fn(this) else null;
  }

  public inline function mapDefault<S>(fn:T->S, def:S):S {
    return if (exists()) fn(this) else def;
  }
}