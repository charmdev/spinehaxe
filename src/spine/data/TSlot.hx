package spine.data;

import spine.Maybe;

typedef TSlot = {
	var name: String;	
	var bone: String;	
	@:optional var color: String;	
	@:optional var attachment: String;
	var blend: Maybe<Int>;
}