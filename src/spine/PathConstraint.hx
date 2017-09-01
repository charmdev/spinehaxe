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

import haxe.ds.Vector;
import spine.attachments.PathAttachment;

class PathConstraint implements Constraint
{
	private static inline var NONE: Int = -1;
	private static inline var BEFORE: Int = -2;
	private static inline var AFTER: Int = -3;

	public var data(get, never): PathConstraintData;
	public var bones(get, never): Array<Bone>;
	
	public var target: Slot;
	public var position: Float;
	public var spacing: Float;
	public var rotateMix: Float;
	public var translateMix: Float;
	
	@:allow(spine) private var _spaces: Vector<Float>;
	@:allow(spine) private var _positions: Vector<Float>;
	@:allow(spine) private var _world: Vector<Float>;
	@:allow(spine) private var _curves: Vector<Float>;
	@:allow(spine) private var _lengths: Vector<Float>;
	@:allow(spine) private var _segments: Vector<Float>;

	public function new(data: PathConstraintData, skeleton: Skeleton)
	{
		if (data == null)
			throw "data cannot be null.";
			
		if (skeleton == null)
			throw "skeleton cannot be null.";
		
		_data = data;
		_bones = [];
		for (boneData in data.bones)
			_bones.push(skeleton.findBone(boneData.name));
		
		target = skeleton.findSlot(data.target.name);
		position = data.position;
		spacing = data.spacing;
		rotateMix = data.rotateMix;
		translateMix = data.translateMix;
		
		_segments = ArrayUtils.allocFloat(10);
	}

	public inline function apply(): Void
	{
		update();
	}

	public function update(): Void
	{
		var attachment: PathAttachment = cast target.attachment;
		if (attachment == null)
			return;

		var rotateMix: Float = this.rotateMix;
		var translateMix: Float = this.translateMix;
		var translate: Bool = (translateMix > 0);
		var rotate: Bool = (rotateMix > 0);
		if (!translate && !rotate)
			return;

		var data: PathConstraintData = this._data;
		var spacingMode: SpacingMode = data.spacingMode;
		var lengthSpacing: Bool = spacingMode == LENGTH;
		var rotateMode: RotateMode = data.rotateMode;
		var tangents: Bool = rotateMode == TANGENT;
		var scale: Bool = rotateMode == CHAINSCALE;
		var boneCount: Int = this._bones.length;
		var spacesCount: Int = tangents ? boneCount : boneCount + 1;
		var bones: Array<Bone> = this._bones;
		
		//_spaces.length = spacesCount;
		if (_spaces == null || _spaces.length != spacesCount)
			_spaces = ArrayUtils.allocFloat(spacesCount);
		
		var spaces: Vector<Float> = this._spaces;
		var lengths: Vector<Float> = null;
		var spacing: Float = this.spacing;
		
		if (scale || lengthSpacing) 
		{
			if (scale) 
			{
				//this._lengths.length = boneCount;
				if (_lengths == null || _lengths.length != boneCount)
					_lengths = ArrayUtils.allocFloat(boneCount);
				
				lengths = this._lengths;
			}
			
			var i: Int = 0;
			var n: Int = spacesCount - 1;
			while (i < n)
			{
				var bone: Bone = bones[i];
				var length: Float = bone.data.length;
				var x: Float = length * bone.a;
				var y: Float = length * bone.c;
				length = Math.sqrt(x * x + y * y);
				
				if (scale)
					lengths[i] = length;
				
				spaces[++i] = lengthSpacing ? Math.max(0, length + spacing) : spacing;
			}
		}
		else 
		{
			for (i in 1...spacesCount)
				spaces[i] = spacing;
		}

		var positions: Vector<Float> = computeWorldPositions(attachment, spacesCount, tangents, data.positionMode == PERCENT, spacingMode == PERCENT);
		var boneX: Float = positions[0];
		var boneY: Float = positions[1];
		var offsetRotation: Float = data.offsetRotation;
		var tip: Bool = false;
		if (offsetRotation == 0)
		{
			tip = (rotateMode == RotateMode.CHAIN);
		}
		else 
		{
			tip = false;
			var pa: Bone = target.bone;
			offsetRotation *= (pa.a * pa.d - pa.b * pa.c > 0) ? MathUtils.degRad : -MathUtils.degRad;
		}
		
		var p: Int = 3;
		var i: Int = 0;
		while (i < boneCount)
		{
			var bone = bones[i];
			bone._worldX += (boneX - bone.worldX) * translateMix;
			bone._worldY += (boneY - bone.worldY) * translateMix;
			
			var x = positions[p]; 
			var y = positions[p + 1];
			var dx: Float = x - boneX;
			var dy: Float = y - boneY;
			if ( scale ) 
			{
				var length = lengths[i];
				if (length != 0) 
				{
					var s: Float = (Math.sqrt(dx * dx + dy * dy) / length - 1) * rotateMix + 1;
					bone._a *= s;
					bone._c *= s;
				}
			}
			
			boneX = x;
			boneY = y;
			
			if (rotate) 
			{
				var a: Float = bone.a;
				var b: Float = bone.b;
				var c: Float = bone.c;
				var d: Float = bone.d;
				var r: Float;
				var cos: Float;
				var sin: Float;
				
				if (tangents) 
					r = positions[p - 1]
				else if (spaces[i + 1] == 0) 
					r = positions[p + 2]
				else 
					r = Math.atan2(dy, dx);
				
				r -= Math.atan2(c, a);
				
				if (tip) 
				{
					cos = Math.cos(r);
					sin = Math.sin(r);
					var length = bone.data.length;
					boneX += (length * (cos * a - sin * c) - dx) * rotateMix;
					boneY += (length * (sin * a + cos * c) - dy) * rotateMix;
				}
				else 
				{
					r += offsetRotation;
				}
				
				if (r > Math.PI) 
					r -= (Math.PI * 2)
				else if (r < -Math.PI) //  
					r += (Math.PI * 2);
				
				r *= rotateMix;
				cos = Math.cos(r);
				sin = Math.sin(r);
				bone._a = cos * a - sin * c;
				bone._b = cos * b - sin * d;
				bone._c = sin * a + cos * c;
				bone._d = sin * b + cos * d;
			}
			
			bone.appliedValid = false;
			bone.updateAppliedTransform();
			
			i++;
			p += 3;
		}
	}

	private function computeWorldPositions(path: PathAttachment, spacesCount: Int, tangents: Bool, percentPosition: Bool, percentSpacing: Bool): Vector<Float>
	{
		var target: Slot = this.target;
		var position: Float = this.position;
		var spaces: Vector<Float> = this._spaces;
		
		//this._positions.length = spacesCount * 3 + 2;
		if (_positions == null || _positions.length != spacesCount * 3 + 2)
			_positions = ArrayUtils.allocFloat(spacesCount * 3 + 2);
		
		var out: Vector<Float> = _positions;
		var world: Vector<Float>;
		var closed: Bool = path.closed;
		var verticesLength: Int = path.worldVerticesLength;
		var curveCount: Int = Math.floor(verticesLength / 6);
		var prevCurve: Int = NONE;

		if (!path.constantSpeed) 
		{
			var lengths: Vector<Float> = path.lengths;
			curveCount -= (closed) ? 1 : 2;
			var pathLength: Float = lengths[curveCount];
			
			if (percentPosition)
				position *= pathLength;
				
			if (percentSpacing) 
				for (i in 0...spacesCount)
					spaces[i] *= pathLength;
			
			//this._world.length = 8;
			if (_world == null || _world.length != 8)
				_world = ArrayUtils.allocFloat(8);
			
			world = this._world;
			
			var o: Int = 0; 
			var curve: Int = 0;
			var i: Int = 0;
			while (i < spacesCount)
			{
				var space: Float = spaces[i];
				position += space;
				var p: Float = position;

				if (closed)
				{
					p %= pathLength;
					if (p < 0) 
						p += pathLength;
					
					curve = 0;
				}
				else if (p < 0) 
				{
					if (prevCurve != BEFORE) 
					{
						prevCurve = BEFORE;
						path.computeWorldVertices2(target, 2, 4, world, 0);
					}
					
					addBeforePosition(p, world, 0, out, o);
					i++;
					o += 3;
					continue;
				} 
				else if (p > pathLength) 
				{
					if (prevCurve != AFTER) 
					{
						prevCurve = AFTER;
						path.computeWorldVertices2(target, verticesLength - 6, 4, world, 0);
					}
					
					addAfterPosition(p - pathLength, world, 0, out, o);
					i++; 
					o += 3;
					continue;
				}
				
				// Determine curve containing position.
				while ( true )
				{
					var length: Float = lengths[curve];
					if (p > length)
					{
						curve++; 
						continue;
					}
					
					if (curve == 0) 
						p /= length;
					else 
					{
						var prev: Float = lengths[curve - 1];
						p = (p - prev) / (length - prev);
					}
					
					break;
				}
				
				if (curve != prevCurve) 
				{
					prevCurve = curve;
					if (closed && curve == curveCount) 
					{
						path.computeWorldVertices2(target, verticesLength - 4, 4, world, 0);
						path.computeWorldVertices2(target, 0, 4, world, 4);
					}
					else 
						path.computeWorldVertices2(target, curve * 6 + 2, 8, world, 0);
				}
				
				addCurvePosition(p, world[0], world[1], world[2], world[3], world[4], world[5], world[6], world[7], out, o, tangents || (i > 0 && space == 0));
				
				i++;
				o += 3;
			}
			
			return out;
		}  
		
		// World vertices.  
		if (closed) 
		{
			verticesLength += 2;
			
			//this._world.length = verticesLength;
			if (_world == null || _world.length != verticesLength)
				_world = ArrayUtils.allocFloat(verticesLength);
			
			world = this._world;
			path.computeWorldVertices2(target, 2, verticesLength - 4, world, 0);
			path.computeWorldVertices2(target, 0, 2, world, verticesLength - 4);
			world[verticesLength - 2] = world[0];
			world[verticesLength - 1] = world[1];
		}
		else 
		{
			curveCount--;
			verticesLength -= 4;
			
			//this._world.length = verticesLength;
			if (_world == null || _world.length != verticesLength)
				_world = ArrayUtils.allocFloat(verticesLength);
			
			world = this._world;
			path.computeWorldVertices2(target, 2, verticesLength, world, 0);
		}  
		
		// Curve lengths.
		//this._curves.length = curveCount;
		if (_curves == null || _curves.length != curveCount)
				_curves = ArrayUtils.allocFloat(curveCount);
		
		var curves: Vector<Float> = this._curves;
		var pathLength: Float = 0.0;
		var x1: Float = world[0];
		var y1: Float = world[1];
		var cx1: Float = 0;
		var cy1: Float = 0;
		var cx2: Float = 0;
		var cy2: Float = 0;
		var x2: Float = 0;
		var y2: Float = 0;
		var tmpx: Float;
		var tmpy: Float;
		var dddfx: Float;
		var dddfy: Float;
		var ddfx: Float;
		var ddfy: Float;
		var dfx: Float;
		var dfy: Float;
		
		var w: Int = 2;
		var i: Int = 0;
		while (i < curveCount)
		{
			cx1 = world[w];
			cy1 = world[w + 1];
			cx2 = world[w + 2];
			cy2 = world[w + 3];
			x2 = world[w + 4];
			y2 = world[w + 5];
			tmpx = (x1 - cx1 * 2 + cx2) * 0.1875;
			tmpy = (y1 - cy1 * 2 + cy2) * 0.1875;
			dddfx = ((cx1 - cx2) * 3 - x1 + x2) * 0.09375;
			dddfy = ((cy1 - cy2) * 3 - y1 + y2) * 0.09375;
			ddfx = tmpx * 2 + dddfx;
			ddfy = tmpy * 2 + dddfy;
			dfx = (cx1 - x1) * 0.75 + tmpx + dddfx * 0.16666667;
			dfy = (cy1 - y1) * 0.75 + tmpy + dddfy * 0.16666667;
			pathLength += Math.sqrt(dfx * dfx + dfy * dfy);
			dfx += ddfx;
			dfy += ddfy;
			ddfx += dddfx;
			ddfy += dddfy;
			pathLength += Math.sqrt(dfx * dfx + dfy * dfy);
			dfx += ddfx;
			dfy += ddfy;
			pathLength += Math.sqrt(dfx * dfx + dfy * dfy);
			dfx += ddfx + dddfx;
			dfy += ddfy + dddfy;
			pathLength += Math.sqrt(dfx * dfx + dfy * dfy);
			curves[i] = pathLength;
			x1 = x2;
			y1 = y2;
			
			i++;
			w += 6;
		}
		
		if (percentPosition)
			position *= pathLength;
		
		if (percentSpacing) 
			for (i in 0...spacesCount)
				spaces[i] *= pathLength;

		var segments: Vector<Float> = this._segments;
		var curveLength: Float = 0;
		var segment: Int;
		
		i = 0;
		var o: Int = 0;
		var curve: Int = 0;
		segment = 0;
		while (i < spacesCount)
		{
			var space = spaces[i];
			position += space;
			var p = position;
			
			if (closed) 
			{
				p %= pathLength;
				if (p < 0) p += pathLength;
				curve = 0;
			}
			else if (p < 0) 
			{
				addBeforePosition(p, world, 0, out, o);
				i++;
				o += 3;
				continue;
			}
			else if (p > pathLength) 
			{
				addAfterPosition(p - pathLength, world, verticesLength - 4, out, o);
				i++;
				o += 3;
				continue;
			}

			// Determine curve containing position.
			while ( true )
			{
				var length = curves[curve];
				if (p > length)
				{
					curve++;
					continue;
				}
				if (curve == 0) 
					p /= length;
				else 
				{
					var prev = curves[curve - 1];
					p = (p - prev) / (length - prev);
				}
				break;
			}  
			
			// Curve segment lengths.  
			if (curve != prevCurve) 
			{
				prevCurve = curve;
				var ii : Int = curve * 6;
				x1 = world[ii];
				y1 = world[ii + 1];
				cx1 = world[ii + 2];
				cy1 = world[ii + 3];
				cx2 = world[ii + 4];
				cy2 = world[ii + 5];
				x2 = world[ii + 6];
				y2 = world[ii + 7];
				tmpx = (x1 - cx1 * 2 + cx2) * 0.03;
				tmpy = (y1 - cy1 * 2 + cy2) * 0.03;
				dddfx = ((cx1 - cx2) * 3 - x1 + x2) * 0.006;
				dddfy = ((cy1 - cy2) * 3 - y1 + y2) * 0.006;
				ddfx = tmpx * 2 + dddfx;
				ddfy = tmpy * 2 + dddfy;
				dfx = (cx1 - x1) * 0.3 + tmpx + dddfx * 0.16666667;
				dfy = (cy1 - y1) * 0.3 + tmpy + dddfy * 0.16666667;
				curveLength = Math.sqrt(dfx * dfx + dfy * dfy);
				segments[0] = curveLength;
				for (ii in 1...8)
				{
					dfx += ddfx;
					dfy += ddfy;
					ddfx += dddfx;
					ddfy += dddfy;
					curveLength += Math.sqrt(dfx * dfx + dfy * dfy);
					segments[ii] = curveLength;
				}
				dfx += ddfx;
				dfy += ddfy;
				curveLength += Math.sqrt(dfx * dfx + dfy * dfy);
				segments[8] = curveLength;
				dfx += ddfx + dddfx;
				dfy += ddfy + dddfy;
				curveLength += Math.sqrt(dfx * dfx + dfy * dfy);
				segments[9] = curveLength;
				segment = 0;
			}  
			
			// Weight by segment length.  
			p *= curveLength;
			while ( true )
			{
				var length = segments[segment];
				if (p > length)
				{
					segment++;
					continue;
				}
				
				if (segment == 0) 
					p /= length;
				else 
				{
					var prev = segments[segment - 1];
					p = segment + (p - prev) / (length - prev);
				}
				break;
			}
			
			addCurvePosition(p * 0.1, x1, y1, cx1, cy1, cx2, cy2, x2, y2, out, o, tangents || (i > 0 && space == 0));
			i++;
			o += 3;
		}
		
		return out;
	}

	private function addBeforePosition(p: Float, temp: Vector<Float>, i: Int, out: Vector<Float>, o: Int): Void
	{
		var x1: Float = temp[i];
		var y1: Float = temp[i + 1];
		var dx: Float = temp[i + 2] - x1;
		var dy: Float = temp[i + 3] - y1;
		var r: Float = Math.atan2(dy, dx);
		
		out[o] = x1 + p * Math.cos(r);
		out[o + 1] = y1 + p * Math.sin(r);
		out[o + 2] = r;
	}

	private function addAfterPosition(p: Float, temp: Vector<Float>, i: Int, out: Vector<Float>, o: Int): Void
	{
		var x1: Float = temp[i + 2];
		var y1: Float = temp[i + 3];
		var dx: Float = x1 - temp[i];
		var dy: Float = y1 - temp[i + 1];
		var r: Float = Math.atan2(dy, dx);
		
		out[o] = x1 + p * Math.cos(r);
		out[o + 1] = y1 + p * Math.sin(r);
		out[o + 2] = r;
	}

	private function addCurvePosition(p: Float, x1: Float, y1: Float, cx1: Float, cy1: Float, cx2: Float, cy2: Float, x2: Float, y2: Float, out: Vector<Float>, o: Int, tangents: Bool): Void
	{
		if (p == 0 || Math.isNaN(p))
			p = 0.0001;
			
		var tt: Float = p * p;
		var ttt: Float = tt * p;
		var u: Float = 1 - p;
		var uu: Float = u * u;
		var uuu: Float = uu * u;
		var ut: Float = u * p;
		var ut3: Float = ut * 3;
		var uut3: Float = u * ut3;
		var utt3: Float = ut3 * p;
		var x: Float = x1 * uuu + cx1 * uut3 + cx2 * utt3 + x2 * ttt;
		var y: Float = y1 * uuu + cy1 * uut3 + cy2 * utt3 + y2 * ttt;
		
		out[o] = x;
		out[o + 1] = y;
		if (tangents)
			out[o + 2] = Math.atan2(y - (y1 * uu + cy1 * ut * 2 + cy2 * tt), x - (x1 * uu + cx1 * ut * 2 + cx2 * tt));
	}

	public function getOrder (): Float 
	{
		return _data.order;
	}
	
	public inline function toString(): String
	{
		return _data.name;
	}
	
	// getters / setters
	private inline function get_bones(): Array<Bone> return _bones;
	private inline function get_data(): PathConstraintData return _data;
	
	@:allow(spine) private var _data: PathConstraintData;
	@:allow(spine) private var _bones: Array<Bone>;
}