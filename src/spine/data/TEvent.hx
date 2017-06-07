package spine.data;

import haxe.DynamicAccess;
import spine.Maybe;

typedef TEvents = DynamicAccess<TEvent>;

typedef TEvent = {
	var int: Maybe<Int>;
	var float: Maybe<Float>;
	var string: Maybe<String>;
}