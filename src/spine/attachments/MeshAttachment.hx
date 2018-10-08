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

package spine.attachments;

import haxe.ds.Vector;
import spine.attachments.AttachmentType.AttachmentIntType;
import spine.attachments.VertexAttachment;

class MeshAttachment extends VertexAttachment
{
	public var parentMesh(get, set): MeshAttachment;

	public var worldVertices: Array<Float>;
	public var uvs:Vector<Float>;
	public var regionUVs: Vector<Float>;
	public var triangles: Array<Int>;
	public var r: Float = 1;
	public var g: Float = 1;
	public var b: Float = 1;
	public var a: Float = 1;
	public var hullLength: Int;
	public var inheritDeform: Bool;

	public var path: String;
	public var rendererObject: Dynamic;
	public var regionU: Float;
	public var regionV: Float;
	public var regionU2: Float;
	public var regionV2: Float;
	public var regionRotate: Bool;
	public var regionOffsetX: Float;  // Pixels stripped from the bottom left, unrotated.  
	public var regionOffsetY: Float;
	public var regionWidth: Float;  // Unrotated, stripped size.  
	public var regionHeight: Float;
	public var regionOriginalWidth: Float;  // Unrotated, unstripped size.  
	public var regionOriginalHeight: Float;

	// Nonessential.
	public var edges: Array<Int>;
	public var width: Float;
	public var height: Float;
    
	public function new(name: String)
	{
		super(name);
		
		type = AttachmentIntType.MESH;
	}

	public function updateUVs(): Void
	{
		var width: Float = regionU2 - regionU;
		var height: Float = regionV2 - regionV;
		var n: Int = regionUVs.length;
		
		if (uvs == null || uvs.length != n)             
			uvs = ArrayUtils.allocFloat( n );
		
		if (regionRotate)
		{
			var i: Int = 0;
			while (i < n)
			{
				uvs[i] = regionU + regionUVs[i + 1] * width;
				uvs[i + 1] = regionV + height - regionUVs[i] * height;
				
				i += 2;
			}
		}
		else 
		{
			var i: Int = 0;
			while (i < n)
			{
				uvs[i] = regionU + regionUVs[i] * width;
				uvs[i + 1] = regionV + regionUVs[i + 1] * height;
				i += 2;
			}
		}
	}

	public inline function applyFFD(sourceAttachment: Attachment): Bool
	{
		return (this == sourceAttachment) || (inheritDeform && (_parentMesh == sourceAttachment));
	}

	// getters / setters
	
	private inline function get_parentMesh(): MeshAttachment
	{
		return _parentMesh;
	}

	private inline function set_parentMesh(parentMesh: MeshAttachment): MeshAttachment
	{
		_parentMesh = parentMesh;
		if (parentMesh != null) 
		{
			bones = parentMesh.bones;
			vertices = parentMesh.vertices;
			worldVerticesLength = parentMesh.worldVerticesLength;
			regionUVs = parentMesh.regionUVs;
			triangles = parentMesh.triangles;
			hullLength = parentMesh.hullLength;
			edges = parentMesh.edges;
			width = parentMesh.width;
			height = parentMesh.height;
		}
		
		return parentMesh;
	}
	
	private var _parentMesh: MeshAttachment;
}