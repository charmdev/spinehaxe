package spine.data;

import spine.Maybe;

typedef TIk = {
	var name: String;
	var order: Maybe<Float>;
	var bones: Array<String>;
	var target: String;
	var bendPositive: Maybe<Bool>;
	var mix: Maybe<Float>;
}