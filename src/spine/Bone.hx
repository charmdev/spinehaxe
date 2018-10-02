/******************************************************************************
 * Spine Runtimes Software License
 * Version 2.3
 * 
 * Copyright (c) 2013-2015, Esoteric Software
 * All rights reserved.
 * 
 * You are granted a perpetual, non-exclusive, non-sublicensable and
 * non-transferable license to use, install, execute and perform the Spine
 * Runtimes Software (the "Software") and derivative works solely for personal
 * or internal use. Without the written permission of Esoteric Software (see
 * Section 2 of the Spine Software License Agreement), you may not (a) modify,
 * translate, adapt or otherwise create derivative works, improvements of the
 * Software or develop new applications using the Software or (b) remove,
 * delete, alter or obscure any trademarks or any copyright, trademark, patent
 * or other intellectual property or proprietary rights notices on or in the
 * Software, including any copy thereof. Redistributions in binary or source
 * form must include this license and terms.
 * 
 * THIS SOFTWARE IS PROVIDED BY ESOTERIC SOFTWARE "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL ESOTERIC SOFTWARE BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS;
 * OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
 * WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR
 * OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
 * ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
 *****************************************************************************/

package spine;

import spine.BoneData;
import spine.Skeleton;
import spine.TransformMode.TransformIntMode;
import spine.Updatable;

class Bone implements Updatable
{
	public static var yDown: Bool;
	
	public var data(get, never): BoneData;
	public var skeleton(get, never): Skeleton;
	public var parent(get, never): Bone;
	public var children(get, never): Array<Bone>;
	public var x: Float;
	public var y: Float;
	public var rotation: Float;
	public var scaleX: Float;
	public var scaleY: Float;
	public var shearX: Float;
	public var shearY: Float;
	public var ax: Float;
	public var ay: Float;
	public var arotation: Float;
	public var ascaleX: Float;
	public var ascaleY: Float;
	public var ashearX: Float;
	public var ashearY: Float;
	public var appliedValid: Bool;
	
	public var a(get, never): Float;
	public var b(get, never): Float;
	public var c(get, never): Float;
	public var d(get, never): Float;
	public var worldX(get, never): Float;
	public var worldY(get, never): Float;
	public var worldRotationX(get, never): Float;
	public var worldRotationY(get, never): Float;
	public var worldScaleX(get, never): Float;
	public var worldScaleY(get, never): Float;

	@:allow(spine) private var _sorted: Bool;

	/** @param parent May be null. */
	public function new(data: BoneData, skeleton: Skeleton, parent: Bone)
	{
		if (data == null)
			throw 'data cannot be null.';
			
		if (skeleton == null)
			throw 'skeleton cannot be null.';
		
		_data = data;
		_skeleton = skeleton;
		_parent = parent;
		setToSetupPose();
	}

	/** Same as updateWorldTransform(). This method exists for Bone to implement Updatable. */
	public function update(): Void
	{
		updateWorldTransformWith(x, y, rotation, scaleX, scaleY, shearX, shearY);
	}

	/** Computes the world SRT using the parent bone and this bone's local SRT. */
	public function updateWorldTransform(): Void
	{
		updateWorldTransformWith(x, y, rotation, scaleX, scaleY, shearX, shearY);
	}

	/** Computes the world SRT using the parent bone and the specified local SRT. */
	public function updateWorldTransformWith(x: Float, y: Float, rotation: Float, scaleX: Float, scaleY: Float, shearX: Float, shearY: Float): Void
	{
		ax = x;
		ay = y;
		arotation = rotation;
		ascaleX = scaleX;
		ascaleY = scaleY;
		ashearX = shearX;
		ashearY = shearY;
		appliedValid = true;
		
		var rotationY: Float = 0;
		var la: Float = 0;
		var lb: Float = 0;
		var lc: Float = 0; 
		var ld: Float = 0;
		var sin: Float = 0;
		var cos: Float = 0;
		var s: Float = 0;

		var parent: Bone = _parent;
		if (parent == null) // Root bone.
		{
			rotationY = rotation + 90 + shearY;
			la = MathUtils.cosDeg(rotation + shearX) * scaleX;
			lb = MathUtils.cosDeg(rotationY) * scaleY;
			lc = MathUtils.sinDeg(rotation + shearX) * scaleX;
			ld = MathUtils.sinDeg(rotationY) * scaleY;
			
			var skeleton: Skeleton = _skeleton;
			if (skeleton.flipX) 
			{
				x = -x;
				la = -la;
				lb = -lb;
			}
			
			if (skeleton.flipY != yDown) 
			{
				y = -y;
				lc = -lc;
				ld = -ld;
			}
			
			_a = la;
			_b = lb;
			_c = lc;
			_d = ld;
			_worldX = x + skeleton.x;
			_worldY = y + skeleton.y;
			
			return;
		}

		var pa: Float = parent._a;
		var pb: Float = parent._b;
		var pc: Float = parent._c;
		var pd: Float = parent._d;
		_worldX = pa * x + pb * y + parent._worldX;
		_worldY = pc * x + pd * y + parent._worldY;

		switch (_data.transformMode) 
		{
			case TransformIntMode.NORMAL:
				rotationY = rotation + 90 + shearY;
				la = MathUtils.cosDeg(rotation + shearX) * scaleX;
				lb = MathUtils.cosDeg(rotationY) * scaleY;
				lc = MathUtils.sinDeg(rotation + shearX) * scaleX;
				ld = MathUtils.sinDeg(rotationY) * scaleY;
				_a = pa * la + pb * lc;
				_b = pa * lb + pb * ld;
				_c = pc * la + pd * lc;
				_d = pc * lb + pd * ld;
				return;
				
			case TransformIntMode.ONLY_TRANSLATION:
				rotationY = rotation + 90 + shearY;
				_a = MathUtils.cosDeg(rotation + shearX) * scaleX;
				_b = MathUtils.cosDeg(rotationY) * scaleY;
				_c = MathUtils.sinDeg(rotation + shearX) * scaleX;
				_d = MathUtils.sinDeg(rotationY) * scaleY;
				
			case TransformIntMode.NO_ROTATION_OR_REFLECTION:
				s = pa * pa + pc * pc;
				var prx: Float = 0;
				if (s > 0.0001) 
				{
					s = Math.abs(pa * pd - pb * pc) / s;
					pb = pc * s;
					pd = pa * s;
					prx = Math.atan2(pc, pa) * MathUtils.radDeg;
				} 
				else 
				{
					pa = 0;	
					pc = 0;
					prx = 90 - Math.atan2(pd, pb) * MathUtils.radDeg;
				}
				var rx: Float = rotation + shearX - prx;
				var ry: Float = rotation + shearY - prx + 90;
				la = MathUtils.cosDeg(rx) * scaleX;
				lb = MathUtils.cosDeg(ry) * scaleY;
				lc = MathUtils.sinDeg(rx) * scaleX;
				ld = MathUtils.sinDeg(ry) * scaleY;
				_a = pa * la - pb * lc;
				_b = pa * lb - pb * ld;
				_c = pc * la + pd * lc;
				_d = pc * lb + pd * ld;

			case TransformIntMode.NO_SCALE, TransformIntMode.NO_SCALE_OR_REFLECTION:
				cos = MathUtils.cosDeg(rotation);
				sin = MathUtils.sinDeg(rotation);
				var za: Float = pa * cos + pb * sin;
				var zc: Float = pc * cos + pd * sin;
				s = Math.sqrt(za * za + zc * zc);
				
				if (s > 0.00001) 
					s = 1 / s;
					
				za *= s;
				zc *= s;
				s = Math.sqrt(za * za + zc * zc);
				var r: Float = Math.PI / 2 + Math.atan2(zc, za);
				var zb: Float = Math.cos(r) * s;
				var zd: Float = Math.sin(r) * s;
				la = MathUtils.cosDeg(shearX) * scaleX;
				lb = MathUtils.cosDeg(90 + shearY) * scaleY;
				lc = MathUtils.sinDeg(shearX) * scaleX;
				ld = MathUtils.sinDeg(90 + shearY) * scaleY;
				_a = za * la + zb * lc;
				_b = za * lb + zb * ld;
				_c = zc * la + zd * lc;
				_d = zc * lb + zd * ld;
				if (_data.transformMode != TransformIntMode.NO_SCALE_OR_REFLECTION ? pa * pd - pb * pc < 0 : skeleton.flipX != skeleton.flipY) 
				{
					_b = -_b;
					_d = -_d;
				}
				return;
		}
			
		if (_skeleton.flipX) 
		{
			_a = -_a;
			_b = -_b;
		}
		if (_skeleton.flipY != yDown)
		{
			_c = -_c;
			_d = -_d;
		}
	}

	public function setToSetupPose(): Void
	{
		x = _data.x;
		y = _data.y;
		rotation = _data.rotation;
		scaleX = _data.scaleX;
		scaleY = _data.scaleY;
		shearX = _data.shearX;
		shearY = _data.shearY;
	}

	public function worldToLocalRotationX(): Float
	{
		var parent: Bone = _parent;
		if (parent == null)
			return arotation;
		
		var pa: Float = parent.a;
		var pb: Float = parent.b;
		var pc: Float = parent.c;
		var pd: Float = parent.d;
		var a: Float = this.a;
		var c: Float = this.c;
		return Math.atan2(pa * c - pc * a, pd * a - pb * c) * MathUtils.radDeg;
	}

	public function worldToLocalRotationY(): Float
	{
		var parent: Bone = _parent;
		if (parent == null)
			return arotation;
		
		var pa: Float = parent.a;
		var pb: Float = parent.b;
		var pc: Float = parent.c;
		var pd: Float = parent.d;
		var b: Float = this.b;
		var d: Float = this.d;
		return Math.atan2(pa * d - pc * b, pd * b - pb * d) * MathUtils.radDeg;
	}

	public function rotateWorld(degrees : Float): Void
	{
		var a: Float = this.a;
		var b: Float = this.b;
		var c: Float = this.c;
		var d: Float = this.d;
		var cos: Float = MathUtils.cosDeg(degrees);
		var sin: Float = MathUtils.sinDeg(degrees);
		this._a = cos * a - sin * c;
		this._b = cos * b - sin * d;
		this._c = sin * a + cos * c;
		this._d = sin * b + cos * d;
		this.appliedValid = false;
	}

	/** Computes the individual applied transform values from the world transform. This can be useful to perform processing using
	 * the applied transform after the world transform has been modified directly (eg, by a constraint).
	 * <p>
	 * Some information is ambiguous in the world transform, such as -1,-1 scale versus 180 rotation. */
	public function updateAppliedTransform(): Void
	{
		appliedValid = true;
		
		var parent: Bone = this.parent;
		if (parent == null) 
		{
			ax = worldX;
			ay = worldY;
			arotation = Math.atan2(c, a) * MathUtils.radDeg;
			ascaleX = Math.sqrt(a * a + c * c);
			ascaleY = Math.sqrt(b * b + d * d);
			ashearX = 0;
			ashearY = Math.atan2(a * b + c * d, a * d - b * c) * MathUtils.radDeg;
			return;
		}
		
		var pa: Float = parent.a;
		var pb: Float = parent.b;
		var pc: Float = parent.c;
		var pd: Float = parent.d;
		var pid: Float = 1 / (pa * pd - pb * pc);
		var dx: Float = worldX - parent.worldX;
		var dy: Float = worldY - parent.worldY;
		ax = (dx * pd * pid - dy * pb * pid);
		ay = (dy * pa * pid - dx * pc * pid);
		var ia: Float = pid * pd;
		var id: Float = pid * pa;
		var ib: Float = pid * pb;
		var ic: Float = pid * pc;
		var ra: Float = ia * a - ib * c;
		var rb: Float = ia * b - ib * d;
		var rc: Float = id * c - ic * a;
		var rd: Float = id * d - ic * b;
		ashearX = 0;
		ascaleX = Math.sqrt(ra * ra + rc * rc);
		if (scaleX > 0.0001) 
		{
			var det = ra * rd - rb * rc;
			ascaleY = det / ascaleX;
			ashearY = Math.atan2(ra * rb + rc * rd, det) * MathUtils.radDeg;
			arotation = Math.atan2(rc, ra) * MathUtils.radDeg;
		}
		else 
		{
			ascaleX = 0;
			ascaleY = Math.sqrt(rb * rb + rd * rd);
			ashearY = 0;
			arotation = 90 - Math.atan2(rd, rb) * MathUtils.radDeg;
		}
	}

	public function worldToLocal(world: Array<Float>): Void
	{
		var a: Float = _a;
		var b: Float = _b;
		var c: Float = _c;
		var d: Float = _d;
		var invDet: Float = 1 / (a * d - b * c);
		var x: Float = world[0] - _worldX;
		var y: Float = world[1] - _worldY;
		world[0] = (x * d * invDet - y * b * invDet);
		world[1] = (y * a * invDet - x * c * invDet);
	}

	public function localToWorld(local: Array<Float>): Void
	{
		var localX: Float = local[0];
		var localY: Float = local[1];
		local[0] = localX * _a + localY * _b + _worldX;
		local[1] = localX * _c + localY * _d + _worldY;
	}

	public function toString(): String
	{
		return _data._name;
	}
	
	// getters / setters
	
	private inline function get_data(): BoneData return _data;
	private inline function get_skeleton() : Skeleton return _skeleton;
	private inline function get_parent(): Bone return _parent;
	private inline function get_children(): Array<Bone> return _children;
	private inline function get_a(): Float return _a;
	private inline function get_b(): Float return _b;
	private inline function get_c(): Float return _c;
	private inline function get_d(): Float return _d;
	private inline function get_worldX(): Float return _worldX;
	private inline function get_worldY(): Float return _worldY;
	private inline function get_worldRotationX(): Float return Math.atan2(_c, _a) * MathUtils.radDeg;
	private inline function get_worldRotationY(): Float return Math.atan2(_d, _b) * MathUtils.radDeg;
	
	private inline function get_worldScaleX(): Float 
	{
		return Math.sqrt(_a * _a + _c * _c);
	}
	
	private inline function get_worldScaleY(): Float 
	{
		return Math.sqrt(_b * _b + _d * _d);
	}
	
	@:allow(spine) private var _data: BoneData;
	@:allow(spine) private var _skeleton: Skeleton;
	@:allow(spine) private var _parent: Bone;
	@:allow(spine) private var _children: Array<Bone> = new Array<Bone>();
	
	@:allow(spine) private var _a : Float;
	@:allow(spine) private var _b : Float;
	@:allow(spine) private var _c : Float;
	@:allow(spine) private var _d : Float;
	@:allow(spine) private var _worldX : Float;
	@:allow(spine) private var _worldY : Float;
}