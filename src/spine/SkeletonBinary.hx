package spine;
import format.swf.Data.RGBA;
import haxe.ds.Vector;
import haxe.io.BufferInput;
import haxe.io.Bytes;
import haxe.io.BytesInput;
import haxe.io.Input;
import haxe.io.Path;
import spine.SkeletonJson.LinkedMesh;
import spine.animation.Animation;
import spine.animation.AttachmentTimeline;
import spine.animation.ColorTimeline;
import spine.animation.CurveTimeline;
import spine.animation.DeformTimeline;
import spine.animation.DrawOrderTimeline;
import spine.animation.EventTimeline;
import spine.animation.IkConstraintTimeline;
import spine.animation.PathConstraintMixTimeline;
import spine.animation.PathConstraintPositionTimeline;
import spine.animation.PathConstraintSpacingTimeline;
import spine.animation.RotateTimeline;
import spine.animation.ScaleTimeline;
import spine.animation.ShearTimeline;
import spine.animation.Timeline;
import spine.animation.TransformConstraintTimeline;
import spine.animation.TranslateTimeline;
import spine.attachments.Attachment;
import spine.attachments.AttachmentLoader;
import spine.attachments.AttachmentType;
import spine.attachments.BoundingBoxAttachment;
import spine.attachments.MeshAttachment;
import spine.attachments.PathAttachment;
import spine.attachments.RegionAttachment;
import spine.attachments.VertexAttachment;
import sys.io.File;
import sys.io.FileInput;

/******************************************************************************
 * Spine Runtimes Software License v2.5
 *
 * Copyright (c) 2013-2016, Esoteric Software
 * All rights reserved.
 *
 * You are granted a perpetual, non-exclusive, non-sublicensable, and
 * non-transferable license to use, install, execute, and perform the Spine
 * Runtimes software and derivative works solely for personal or internal
 * use. Without the written permission of Esoteric Software (see Section 2 of
 * the Spine Software License Agreement), you may not (a) modify, translate,
 * adapt, or develop new applications using the Spine Runtimes or otherwise
 * create derivative works or improvements of the Spine Runtimes or (b) remove,
 * delete, alter, or obscure any trademarks or any copyright, trademark, patent,
 * or other intellectual property or proprietary rights notices on or in the
 * Software, including any copy thereof. Redistributions in binary or source
 * form must include this license and terms.
 *
 * THIS SOFTWARE IS PROVIDED BY ESOTERIC SOFTWARE "AS IS" AND ANY EXPRESS OR
 * IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
 * EVENT SHALL ESOTERIC SOFTWARE BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO,
 * PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES, BUSINESS INTERRUPTION, OR LOSS OF
 * USE, DATA, OR PROFITS) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER
 * IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
 * ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
 * POSSIBILITY OF SUCH DAMAGE.
 *****************************************************************************/
 
class SkeletonBinary 
{
	public static inline var BONE_ROTATE:Int = 0;
	public static inline var BONE_TRANSLATE:Int = 1;
	public static inline var BONE_SCALE:Int = 2;
	public static inline var BONE_SHEAR:Int = 3;

	public static inline var SLOT_ATTACHMENT:Int = 0;
	public static inline var SLOT_COLOR:Int = 1;
	public static inline var SLOT_TWO_COLOR:Int = 2;

	public static inline var PATH_POSITION:Int = 0;
	public static inline var PATH_SPACING:Int = 1;
	public static inline var PATH_MIX:Int = 2;

	public static inline var CURVE_LINEAR:Int = 0;
	public static inline var CURVE_STEPPED:Int = 1;
	public static inline var CURVE_BEZIER:Int = 2;
	
	/**
	 * Helper Bytes for reading float values from data
	 */
	private static var floatBuffer:Bytes;
	/**
	 * Helper object for reading color values
	 */
	private static var rgba:RGBA;

	public var scale:Float;

	private var attachmentLoader:AttachmentLoader;
	private var buffer:Bytes; // = new byte[32];
	private var linkedMeshes:Array<LinkedMesh> = new Array<LinkedMesh>();
	
	public function new(attachmentLoader:AttachmentLoader) 
	{
		if (floatBuffer == null)
		{
			floatBuffer = Bytes.alloc(4);
			rgba = new RGBA();
		}
		
		this.attachmentLoader = attachmentLoader;
		buffer = Bytes.alloc(32);
		scale = 1;
	}
	
	public function readSkeletonDataFromPath(path:String):SkeletonData 
	{
		var input:FileInput = File.read(path, true);
		var skeletonData:SkeletonData = readSkeletonDataFromInput(input);
		input.close();
		skeletonData.name = Path.withoutExtension(Path.withoutDirectory(path));
		return skeletonData;
	}
	
	public function readSkeletonDataFromBytes(bytes:Bytes, name:String):SkeletonData 
	{
		var input:BytesInput = new BytesInput(bytes);
		var skeletonData:SkeletonData = readSkeletonDataFromInput(input);
		skeletonData.name = name;
		return skeletonData;
	}

	public static var /*TransformMode[]*/ TransformModeValues:Array<Int> = [
		0,		// TransformMode.Normal
		7, 		// TransformMode.OnlyTranslation
		1,		// TransformMode.NoRotationOrReflection
		2,		// TransformMode.NoScale
		6		// TransformMode.NoScaleOrReflection
	];

	public function readSkeletonDataFromInput(input:Input):SkeletonData 
	{
		var scale:Float = this.scale;
		
		var skeletonData = new SkeletonData();
		skeletonData.hash = ReadString(input);
		
		if (skeletonData.hash.length == 0) 
		{
			skeletonData.hash = null;
		}
		
		skeletonData.version = ReadString(input);
		if (skeletonData.version.length == 0) 
		{
			skeletonData.version = null;
		}
		
		skeletonData.width = ReadFloat(input);
		skeletonData.height = ReadFloat(input);

		var nonessential:Bool = ReadBoolean(input);
		if (nonessential) 
		{
			skeletonData.fps = ReadFloat(input);
			skeletonData.imagesPath = ReadString(input);
			if (skeletonData.imagesPath.length == 0) 
			{
				skeletonData.imagesPath = null;
			}
		}

		// Bones.
		var n:Int = ReadVarint(input, true);
		for (i in 0...n) 
		{
			var name:String = ReadString(input);
			var parent:BoneData = (i == 0) ? null : skeletonData.bones[ReadVarint(input, true)];
			var data:BoneData = new BoneData(i, name, parent);
			data.rotation = ReadFloat(input);		
			data.x = ReadFloat(input) * scale;
			data.y = ReadFloat(input) * scale;
			data.scaleX = ReadFloat(input);
			data.scaleY = ReadFloat(input);
			data.shearX = ReadFloat(input);
			data.shearY = ReadFloat(input);
			data.length = ReadFloat(input) * scale;
			data.transformMode = TransformModeValues[ReadVarint(input, true)];
			
			if (nonessential) 
			{
				ReadInt(input); // Skip bone color.
			}
			
			skeletonData.bones.push(data);
		}

		// Slots.
		n = ReadVarint(input, true);
		for (i in 0...n) 
		{
			var slotName:String = ReadString(input);
			var boneData:BoneData = skeletonData.bones[ReadVarint(input, true)];
			var slotData:SlotData = new SlotData(i, slotName, boneData);
			var color:RGBA = ReadInt(input);
			slotData.r = color.r / 255;
			slotData.g = color.g / 255;
			slotData.b = color.b / 255;
			slotData.a = color.a / 255;
			slotData.attachmentName = ReadString(input);
			slotData.blendMode = ReadVarint(input, true);
			skeletonData.slots.push(slotData);
		}

		// IK constraints.
		n = ReadVarint(input, true);
		for (i in 0...n) 
		{
			var data:IkConstraintData = new IkConstraintData(ReadString(input));
			data.order = ReadVarint(input, true);
			var nn = ReadVarint(input, true);
			for (ii in 0...nn)
			{
				data.bones.push(skeletonData.bones[ReadVarint(input, true)]);
			}
			data.target = skeletonData.bones[ReadVarint(input, true)];
			data.mix = ReadFloat(input);
			data.bendDirection = ReadSByte(input);
			skeletonData.ikConstraints.push(data);
		}

		// Transform constraints.
		n = ReadVarint(input, true);
		for (i in 0...n) 
		{
			var data:TransformConstraintData = new TransformConstraintData(ReadString(input));
			data.order = ReadVarint(input, true);
			var nn = ReadVarint(input, true);
			for (ii in 0...nn)
			{
				data.bones.push(skeletonData.bones[ReadVarint(input, true)]);
			}
			data.target = skeletonData.bones[ReadVarint(input, true)];
			data.offsetRotation = ReadFloat(input);
			data.offsetX = ReadFloat(input) * scale;
			data.offsetY = ReadFloat(input) * scale;
			data.offsetScaleX = ReadFloat(input);
			data.offsetScaleY = ReadFloat(input);
			data.offsetShearY = ReadFloat(input);
			data.rotateMix = ReadFloat(input);
			data.translateMix = ReadFloat(input);
			data.scaleMix = ReadFloat(input);
			data.shearMix = ReadFloat(input);
			skeletonData.transformConstraints.push(data);
		}

		// Path constraints
		n = ReadVarint(input, true);
		for (i in 0...n) 
		{
			var data:PathConstraintData = new PathConstraintData(ReadString(input));
			data.order = ReadVarint(input, true);
			var nn = ReadVarint(input, true);
			for (ii in 0...nn)
			{
				data.bones.push(skeletonData.bones[ReadVarint(input, true)]);
			}
			
			data.target = skeletonData.slots[ReadVarint(input, true)];
			
			data.positionMode = switch (ReadVarint(input, true))
			{
				case 0:
					PositionMode.FIXED;
				default:
					PositionMode.PERCENT;
			};
			
			data.spacingMode = switch (ReadVarint(input, true))
			{
				case 0:
					SpacingMode.LENGTH;
				case 1:
					SpacingMode.FIXED;	
				default:
					SpacingMode.PERCENT;
			};
			
			data.rotateMode = switch (ReadVarint(input, true))
			{
				case 0:
					RotateMode.TANGENT;
				case 1:
					RotateMode.CHAIN;	
				default:
					RotateMode.CHAINSCALE;
			};
			
			data.offsetRotation = ReadFloat(input);
			data.position = ReadFloat(input);
			
			if (data.positionMode == PositionMode.FIXED) 
			{
				data.position *= scale;
			}
			
			data.spacing = ReadFloat(input);
			if (data.spacingMode == SpacingMode.LENGTH || data.spacingMode == SpacingMode.FIXED) 
			{
				data.spacing *= scale;
			}
			
			data.rotateMix = ReadFloat(input);
			data.translateMix = ReadFloat(input);
			skeletonData.pathConstraints.push(data);
		}

		// Default skin.
		var defaultSkin:Skin = ReadSkin(input, "default", nonessential);
		if (defaultSkin != null) 
		{
			skeletonData.defaultSkin = defaultSkin;
			skeletonData.skins.push(defaultSkin);
		}

		// Skins.
		n = ReadVarint(input, true);
		for (i in 0...n)
		{
			skeletonData.skins.push(ReadSkin(input, ReadString(input), nonessential));
		}

		// Linked meshes.
		for (i in 0...linkedMeshes.length) 
		{
			var linkedMesh:LinkedMesh = linkedMeshes[i];
			var skin:Skin = (linkedMesh.skin == null) ? skeletonData.defaultSkin : skeletonData.findSkin(linkedMesh.skin);
			if (skin == null) 
			{
				throw ("Skin not found: " + linkedMesh.skin);
			}
			
			var parent:Attachment = skin.getAttachment(linkedMesh.slotIndex, linkedMesh.parent);
			if (parent == null) 
			{
				throw ("Parent mesh not found: " + linkedMesh.parent);
			}
			
			linkedMesh.mesh.parentMesh = cast parent;
			linkedMesh.mesh.updateUVs();
		}
		linkedMeshes = [];

		// Events.
		n = ReadVarint(input, true);
		for (i in 0...n) 
		{
			var data:EventData = new EventData(ReadString(input));
			data.intValue = ReadVarint(input, false);
			data.floatValue = ReadFloat(input);
			data.stringValue = ReadString(input);
			skeletonData.events.push(data);
		}

		// Animations.
		n = ReadVarint(input, true);
		for (i in 0...n)
		{
			ReadAnimation(ReadString(input), input, skeletonData);
		}
		
		return skeletonData;
	}
	
	/// <returns>May be null.</returns>
	private function ReadSkin(input:Input, skinName:String, nonessential:Bool):Skin
	{
		var slotCount:Int = ReadVarint(input, true);
		if (slotCount == 0) 
			return null;
		
		var skin:Skin = new Skin(skinName);
		for (i in 0...slotCount) 
		{
			var slotIndex:Int = ReadVarint(input, true);
			var nn:Int = ReadVarint(input, true);
			for (ii in 0...nn) 
			{
				var name:String = ReadString(input);
				var attachment:Attachment = ReadAttachment(input, skin, slotIndex, name, nonessential);
				if (attachment != null) 
				{
					skin.addAttachment(slotIndex, name, attachment);
				}
			}
		}
		
		return skin;
	}
	
	private function ReadAttachment(input:Input, skin:Skin, slotIndex:Int, attachmentName:String, nonessential:Bool):Attachment 
	{
		var scale:Float = this.scale;

		var name:String = ReadString(input);
		if (name == null) 
			name = attachmentName;
		
		var type:Int = /*(AttachmentType)*/ input.readByte();
		switch (type) 
		{
			case 0: //AttachmentType.Region:
				var path:String = ReadString(input);
				var rotation:Float = ReadFloat(input);
				var x:Float = ReadFloat(input);
				var y:Float = ReadFloat(input);
				var scaleX:Float = ReadFloat(input);
				var scaleY:Float = ReadFloat(input);
				var width:Float = ReadFloat(input);
				var height:Float = ReadFloat(input);
				var color:RGBA = ReadInt(input);

				if (path == null) 
				{
					path = name;
				}
				
				var region:RegionAttachment = attachmentLoader.newRegionAttachment(skin, name, path);
				if (region == null) 
				{
					return null;
				}
				
				region.path = path;
				region.x = x * scale;
				region.y = y * scale;
				region.scaleX = scaleX;
				region.scaleY = scaleY;
				region.rotation = rotation;
				region.width = width * scale;
				region.height = height * scale;
				region.r = color.r / 255;
				region.g = color.g / 255;
				region.b = color.b / 255;
				region.a = color.a / 255;
				region.updateOffset();
				return region;
			
			case 1: //AttachmentType.Boundingbox:
				var vertexCount:Int = ReadVarint(input, true);
				var vertices:Vertices = ReadVertices(input, vertexCount);
				if (nonessential) 
				{
					ReadInt(input); //int color = nonessential ? ReadInt(input) : 0; // Avoid unused local warning.
				}
				
				var box:BoundingBoxAttachment = attachmentLoader.newBoundingBoxAttachment(skin, name);
				if (box == null) 
				{
					return null;
				}
				box.worldVerticesLength = vertexCount << 1;
				box.vertices = vertices.vertices;
				box.bones = vertices.bones;      
				return box;
			
			case 2: // AttachmentType.Mesh:
				var path:String = ReadString(input);
				var color:RGBA = ReadInt(input);
				var vertexCount:Int = ReadVarint(input, true);			
				var uvs:Vector<Float> = ReadFloatArray(input, vertexCount << 1, 1);
				var triangles:Array<Int> = ReadShortArray(input);
				var vertices:Vertices = ReadVertices(input, vertexCount);
				var hullLength:Int = ReadVarint(input, true);
				var edges:Array<Int> = null;
				var width:Float = 0;
				var height:Float = 0;
				if (nonessential) 
				{
					edges = ReadShortArray(input);
					width = ReadFloat(input);
					height = ReadFloat(input);
				}

				if (path == null) 
				{
					path = name;
				}
				
				var mesh:MeshAttachment = attachmentLoader.newMeshAttachment(skin, name, path);
				if (mesh == null) 
				{
					return null;
				}
				
				mesh.path = path;
				mesh.r = color.r / 255;
				mesh.g = color.g / 255;
				mesh.b = color.b / 255;
				mesh.a = color.a / 255;
				mesh.bones = vertices.bones;
				mesh.vertices = vertices.vertices;
				mesh.worldVerticesLength = vertexCount << 1;
				mesh.triangles = triangles;
				mesh.regionUVs = uvs;
				mesh.updateUVs();
				mesh.hullLength = hullLength << 1;
				if (nonessential) 
				{
					mesh.edges = edges;
					mesh.width = width * scale;
					mesh.height = height * scale;
				}
				return mesh;
			
			case 3: //AttachmentType.Linkedmesh:
				var path:String = ReadString(input);
				var color:RGBA = ReadInt(input);
				var skinName:String = ReadString(input);
				var parent:String = ReadString(input);
				var inheritDeform:Bool = ReadBoolean(input);
				var width:Float = 0;
				var height:Float = 0;
				if (nonessential) 
				{
					width = ReadFloat(input);
					height = ReadFloat(input);
				}

				if (path == null) 
				{
					path = name;
				}
				
				var mesh:MeshAttachment = attachmentLoader.newMeshAttachment(skin, name, path);
				if (mesh == null) 
				{
					return null;
				}
				
				mesh.path = path;
				mesh.r = color.r / 255;
				mesh.g = color.g / 255;
				mesh.b = color.b / 255;
				mesh.a = color.a / 255;
				mesh.inheritDeform = inheritDeform;
				if (nonessential) 
				{
					mesh.width = width * scale;
					mesh.height = height * scale;
				}
				
				linkedMeshes.push(new LinkedMesh(mesh, skinName, slotIndex, parent));
				return mesh;
			
			case 4: //AttachmentType.Path:
				var closed:Bool = ReadBoolean(input);
				var constantSpeed:Bool = ReadBoolean(input);
				var vertexCount:Int = ReadVarint(input, true);
				var vertices:Vertices = ReadVertices(input, vertexCount);
				var n = Std.int(vertexCount / 3);
				var lengths:Vector<Float> = ArrayUtils.allocFloat(n); // new float[vertexCount / 3];
				for (i in 0...n)
				{
					lengths[i] = ReadFloat(input) * scale;
				}
				if (nonessential) 
				{
					ReadInt(input); //int color = nonessential ? ReadInt(input) : 0;
				}

				var path:PathAttachment = attachmentLoader.newPathAttachment(skin, name);
				if (path == null) 
				{
					return null;
				}
				path.closed = closed;
				path.constantSpeed = constantSpeed;
				path.worldVerticesLength = vertexCount << 1;
				path.vertices = vertices.vertices;
				path.bones = vertices.bones;
				path.lengths = lengths;
				return path;
			
			default:
				
		}
		return null;
	}
	
	private function ReadVertices(input:Input, vertexCount:Int):Vertices
	{
		var scale:Float = this.scale;
		var verticesLength:Int = vertexCount << 1;
		var vertices:Vertices = new Vertices();
		
		if (!ReadBoolean(input)) 
		{
			vertices.vertices = ReadFloatArray(input, verticesLength, scale);
			return vertices;
		}
		
		var weights:Vector<Float> = ArrayUtils.allocFloat(verticesLength * 3 * 3); // new ExposedList<float>(verticesLength * 3 * 3);
		var bonesArray:Array<Int> = []; // new ExposedList<int>(verticesLength * 3);
		var weightsIndex:Int = 0;
		for (i in 0...vertexCount) 
		{
			var boneCount:Int = ReadVarint(input, true);
			bonesArray.push(boneCount);
			for (ii in 0...boneCount) 
			{
				bonesArray.push(ReadVarint(input, true));
				weights[weightsIndex++] = ReadFloat(input) * scale;
				weights[weightsIndex++] = ReadFloat(input) * scale;
				weights[weightsIndex++] = ReadFloat(input);
			}
		}

		vertices.vertices = weights;
		vertices.bones = bonesArray;
		return vertices;
	}
	
	private function ReadFloatArray(input:Input, n:Int, scale:Float):Vector<Float>
	{
		var array:Vector<Float> = ArrayUtils.allocFloat(n); // new float[n];
		if (scale == 1) 
		{
			for (i in 0...n)
			{
				array[i] = ReadFloat(input);
			}
		} 
		else 
		{
			for (i in 0...n)
			{
				array[i] = ReadFloat(input) * scale;
			}
		}
		
		return array;
	}
	
	private function ReadShortArray(input:Input):Array<Int> 
	{
		var n:Int = ReadVarint(input, true);
		var array:Array<Int> = []; // n is the length of this array
		for (i in 0...n) 
			array[i] = (input.readByte() << 8) | input.readByte();
		
		return array;
	}

	private function ReadAnimation(name:String, input:Input, skeletonData:SkeletonData):Void
	{
		var timelines:Array<Timeline> = [];
		var scale:Float = this.scale;
		var duration:Float = 0;

		// Slot timelines.
		var n = ReadVarint(input, true);
		for (i in 0...n) 
		{
			var slotIndex:Int = ReadVarint(input, true);
			var nn = ReadVarint(input, true);
			for (ii in 0...nn) 
			{
				var timelineType:Int = input.readByte();
				var frameCount:Int = ReadVarint(input, true);
				
				switch (timelineType) 
				{
					case SLOT_COLOR:
						var timeline:ColorTimeline = new ColorTimeline(frameCount);
						timeline.slotIndex = slotIndex;
						for (frameIndex in 0...frameCount) 
						{
							var time:Float = ReadFloat(input);
							var color:RGBA = ReadInt(input);
							var r:Float = color.r / 255;
							var g:Float = color.g / 255;
							var b:Float = color.b / 255;
							var a:Float = color.a / 255;
							timeline.setFrame(frameIndex, time, r, g, b, a);
							if (frameIndex < frameCount - 1) 
							{
								ReadCurve(input, frameIndex, timeline);
							}
						}
						timelines.push(timeline);
						duration = Math.max(duration, timeline.frames[(timeline.frameCount - 1) * ColorTimeline.ENTRIES]);
					
					case SLOT_ATTACHMENT:
						var timeline:AttachmentTimeline = new AttachmentTimeline(frameCount);
						timeline.slotIndex = slotIndex;
						for (frameIndex in 0...frameCount)
						{
							timeline.setFrame(frameIndex, ReadFloat(input), ReadString(input));
						}
						timelines.push(timeline);
						duration = Math.max(duration, timeline.frames[frameCount - 1]);	
					
					default:
						
				}
			}
		}

		// Bone timelines.
		n = ReadVarint(input, true);
		for (i in 0...n) 
		{
			var boneIndex:Int = ReadVarint(input, true);
			var nn = ReadVarint(input, true);
			for (ii in 0...nn) 
			{
				var timelineType:Int = input.readByte();
				var frameCount:Int = ReadVarint(input, true);
				switch (timelineType) 
				{
					case BONE_ROTATE:
						var timeline:RotateTimeline = new RotateTimeline(frameCount);
						timeline.boneIndex = boneIndex;
						for (frameIndex in 0...frameCount) 
						{
							timeline.setFrame(frameIndex, ReadFloat(input), ReadFloat(input));
							if (frameIndex < frameCount - 1) 
							{
								ReadCurve(input, frameIndex, timeline);
							}
						}
						timelines.push(timeline);
						duration = Math.max(duration, timeline.frames[(frameCount - 1) * RotateTimeline.ENTRIES]);
					
					case BONE_TRANSLATE | BONE_SCALE | BONE_SHEAR:
						
						var timeline:TranslateTimeline = null;
						var timelineScale:Float = 1;
						if (timelineType == BONE_SCALE)
						{
							timeline = new ScaleTimeline(frameCount);
						}
						else if (timelineType == BONE_SHEAR)
						{
							timeline = new ShearTimeline(frameCount);
						}
						else 
						{
							timeline = new TranslateTimeline(frameCount);
							timelineScale = scale;
						}
						timeline.boneIndex = boneIndex;
						for (frameIndex in 0...frameCount) 
						{
							timeline.setFrame(frameIndex, ReadFloat(input), ReadFloat(input) * timelineScale, ReadFloat(input) * timelineScale);
							if (frameIndex < frameCount - 1) 
							{
								ReadCurve(input, frameIndex, timeline);
							}
						}
						timelines.push(timeline);
						duration = Math.max(duration, timeline.frames[(frameCount - 1) * TranslateTimeline.ENTRIES]);
					
					default:
						
				}
			}
		}

		// IK timelines.
		n = ReadVarint(input, true);
		for (i in 0...n) 
		{				
			var index:Int = ReadVarint(input, true);
			var frameCount:Int = ReadVarint(input, true);
			var timeline:IkConstraintTimeline = new IkConstraintTimeline(frameCount);
			timeline.ikConstraintIndex = index;
			for (frameIndex in 0...frameCount) 
			{
				timeline.setFrame(frameIndex, ReadFloat(input), ReadFloat(input), ReadSByte(input));
				if (frameIndex < frameCount - 1) 
				{
					ReadCurve(input, frameIndex, timeline);
				}
			}
			timelines.push(timeline);
			duration = Math.max(duration, timeline.frames[(frameCount - 1) * IkConstraintTimeline.ENTRIES]);
		}

		// Transform constraint timelines.
		n = ReadVarint(input, true);
		for (i in 0...n) 
		{
			var index:Int = ReadVarint(input, true);
			var frameCount:Int = ReadVarint(input, true);
			var timeline:TransformConstraintTimeline = new TransformConstraintTimeline(frameCount);
			timeline.transformConstraintIndex = index;
			for (frameIndex in 0...frameCount) 
			{
				timeline.setFrame(frameIndex, ReadFloat(input), ReadFloat(input), ReadFloat(input), ReadFloat(input), ReadFloat(input));
				if (frameIndex < frameCount - 1) 
				{
					ReadCurve(input, frameIndex, timeline);
				}
			}
			timelines.push(timeline);
			duration = Math.max(duration, timeline.frames[(frameCount - 1) * TransformConstraintTimeline.ENTRIES]);
		}

		// Path constraint timelines.
		n = ReadVarint(input, true);
		for (i in 0...n) 
		{
			var index:Int = ReadVarint(input, true);
			var data:PathConstraintData = skeletonData.pathConstraints[index];
			var nn = ReadVarint(input, true);
			for (ii in 0...nn) 
			{
				var timelineType:Int = input.readByte(); //  ReadSByte(input); // TODO: check it...
				var frameCount:Int = ReadVarint(input, true);
				switch (timelineType) 
				{
					case PATH_POSITION | PATH_SPACING:
						var timeline:PathConstraintPositionTimeline;
						var timelineScale:Float = 1;
						if (timelineType == PATH_SPACING)
						{
							timeline = new PathConstraintSpacingTimeline(frameCount);
							if (data.spacingMode == SpacingMode.LENGTH || data.spacingMode == SpacingMode.FIXED) 
							{
								timelineScale = scale; 
							}
						} 
						else 
						{
							timeline = new PathConstraintPositionTimeline(frameCount);
							if (data.positionMode == PositionMode.FIXED) 
							{
								timelineScale = scale;
							}
						}
						timeline.pathConstraintIndex = index;
						for (frameIndex in 0...frameCount) 
						{                                    
							timeline.setFrame(frameIndex, ReadFloat(input), ReadFloat(input) * timelineScale);
							if (frameIndex < frameCount - 1) 
							{
								ReadCurve(input, frameIndex, timeline);
							}
						}
						timelines.push(timeline);
						duration = Math.max(duration, timeline.frames[(frameCount - 1) * PathConstraintPositionTimeline.ENTRIES]);
					
					case PATH_MIX:
							var timeline:PathConstraintMixTimeline = new PathConstraintMixTimeline(frameCount);
							timeline.pathConstraintIndex = index;
							for (frameIndex in 0...frameCount) 
							{
								timeline.setFrame(frameIndex, ReadFloat(input), ReadFloat(input), ReadFloat(input));
								if (frameIndex < frameCount - 1)
								{
									ReadCurve(input, frameIndex, timeline);
								}
							}
							timelines.push(timeline);
							duration = Math.max(duration, timeline.frames[(frameCount - 1) * PathConstraintMixTimeline.ENTRIES]);
					
					default:
						
				}
			}
		}

		// Deform timelines.
		n = ReadVarint(input, true);
		for (i in 0...n) 
		{
			var skin:Skin = skeletonData.skins[ReadVarint(input, true)];
			var nn = ReadVarint(input, true);
			for (ii in 0...nn) 
			{
				var slotIndex:Int = ReadVarint(input, true);
				var nnn = ReadVarint(input, true);
				for (iii in 0...nnn) 
				{
					var attachment:VertexAttachment = cast skin.getAttachment(slotIndex, ReadString(input));
					var weighted:Bool = (attachment.bones != null);
					var vertices:Vector<Float> = attachment.vertices;
					var deformLength:Int = weighted ? Std.int(vertices.length / 3 * 2) : vertices.length;

					var frameCount:Int = ReadVarint(input, true);
					var timeline:DeformTimeline = new DeformTimeline(frameCount);
					timeline.slotIndex = slotIndex;
					timeline.attachment = attachment;
					
					for (frameIndex in 0...frameCount) 
					{
						var time:Float = ReadFloat(input);
						var deform:Vector<Float> = null;
						var end:Int = ReadVarint(input, true);
						if (end == 0)
						{
							deform = weighted ? ArrayUtils.allocFloat(deformLength) : vertices;
						}
						else 
						{
							deform = ArrayUtils.allocFloat(deformLength);
							var start:Int = ReadVarint(input, true);
							end += start;
							if (scale == 1) 
							{
								for (v in start...end)
								{
									deform[v] = ReadFloat(input);
								}
							} 
							else 
							{
								for (v in start...end)
								{
									deform[v] = ReadFloat(input) * scale;
								}
							}
							if (!weighted) 
							{
								var vn = deform.length;
								for (v in 0...vn)
								{
									deform[v] += vertices[v];
								}
							}
						}

						timeline.setFrame(frameIndex, time, deform);
						if (frameIndex < frameCount - 1) 
						{
							ReadCurve(input, frameIndex, timeline);
						}
					}							
					timelines.push(timeline);
					duration = Math.max(duration, timeline.frames[frameCount - 1]);
				}
			}
		}

		// Draw order timeline.
		var drawOrderCount:Int = ReadVarint(input, true);
		if (drawOrderCount > 0) 
		{
			var timeline:DrawOrderTimeline = new DrawOrderTimeline(drawOrderCount);
			var slotCount:Int = skeletonData.slots.length;
			for (i in 0...drawOrderCount) 
			{
				var time:Float = ReadFloat(input);
				var offsetCount:Int = ReadVarint(input, true);
				var drawOrder:Array<Int> = []; // new int[slotCount];
				var ii:Int = slotCount - 1;
				while (ii >= 0)
				{
					drawOrder[ii] = -1;
					ii--;
				}
				var unchanged:Array<Int> = []; // new int[slotCount - offsetCount];
				var originalIndex:Int = 0;
				var unchangedIndex:Int = 0;
				for (ii in 0...offsetCount) 
				{
					var slotIndex:Int = ReadVarint(input, true);
					// Collect unchanged items.
					while (originalIndex != slotIndex)
					{
						unchanged[unchangedIndex++] = originalIndex++;
					}
					// Set changed items.
					drawOrder[originalIndex + ReadVarint(input, true)] = originalIndex++;
				}
				// Collect remaining unchanged items.
				while (originalIndex < slotCount)
				{
					unchanged[unchangedIndex++] = originalIndex++;
				}
				// Fill in unchanged items.
				var ii:Int = slotCount - 1;
				while (ii >= 0)
				{
					if (drawOrder[ii] == -1) drawOrder[ii] = unchanged[--unchangedIndex];
					ii--;
				}
				timeline.setFrame(i, time, drawOrder);
			}
			timelines.push(timeline);
			duration = Math.max(duration, timeline.frames[drawOrderCount - 1]);
		}

		// Event timeline.
		var eventCount:Int = ReadVarint(input, true);
		if (eventCount > 0) 
		{
			var timeline:EventTimeline = new EventTimeline(eventCount);
			for (i in 0...eventCount) 
			{
				var time:Float = ReadFloat(input);
				var eventData:EventData = skeletonData.events[ReadVarint(input, true)];
				var e:Event = new Event(time, eventData);
				e.intValue = ReadVarint(input, false);
				e.floatValue = ReadFloat(input);
				e.stringValue = ReadBoolean(input) ? ReadString(input) : eventData.stringValue;
				timeline.setFrame(i, e);
			}
			timelines.push(timeline);
			duration = Math.max(duration, timeline.frames[eventCount - 1]);
		}

		skeletonData.animations.push(new Animation(name, timelines, duration));
	}
	
	private function ReadCurve(input:Input, frameIndex:Int, timeline:CurveTimeline):Void 
	{
		switch (input.readByte()) 
		{
			case CURVE_STEPPED:
				timeline.setStepped(frameIndex);
			
			case CURVE_BEZIER:
				timeline.setCurve(frameIndex, ReadFloat(input), ReadFloat(input), ReadFloat(input), ReadFloat(input));
			
			default:
				
		}
	}
	
	private static function ReadSByte(input:Input):Int // TODO: check it and all places where it's used
	{
		var value:Int = input.readByte();
		if (value == -1) throw "End of stream exception";
		return (value > 127) ? -1 : 1;
	}
	
	private static function ReadBoolean(input:Input):Bool
	{
		return (input.readByte() != 0);
	}
	
	private static function ReadFloat(input:Input):Float
	{
		floatBuffer.set(3, input.readByte());
		floatBuffer.set(2, input.readByte());
		floatBuffer.set(1, input.readByte());
		floatBuffer.set(0, input.readByte());
		return floatBuffer.getFloat(0);
	}
	
	private static function ReadInt(input:Input):RGBA 
	{
		var r:Int = input.readByte();
		var g:Int = input.readByte();
		var b:Int = input.readByte();
		var a:Int = input.readByte();
		rgba.set(r, g, b, a);
		return rgba;
	//	return (input.readByte() << 24) + (input.readByte() << 16) + (input.readByte() << 8) + input.readByte();
	}
	
	private static function ReadVarint(input:Input, optimizePositive:Bool):Int
	{
		var b:Int = input.readByte();
		var result:Int = b & 0x7F;
		if ((b & 0x80) != 0) 
		{
			b = input.readByte();
			result |= (b & 0x7F) << 7;
			if ((b & 0x80) != 0) 
			{
				b = input.readByte();
				result |= (b & 0x7F) << 14;
				if ((b & 0x80) != 0) 
				{
					b = input.readByte();
					result |= (b & 0x7F) << 21;
					if ((b & 0x80) != 0) result |= (input.readByte() & 0x7F) << 28;
				}
			}
		}
		
		return optimizePositive ? result : ((result >> 1) ^ -(result & 1));
	}
	
	private function ReadString(input:Input):String
	{
		var byteCount:Int = ReadVarint(input, true);
		
		switch (byteCount) 
		{
			case 0:
				return null;
			case 1:
				return "";
			default:
				
		}
		
		byteCount--;
		var buffer:Bytes = this.buffer;
		if (buffer.length < byteCount) buffer = Bytes.alloc(byteCount);
		ReadFully(input, buffer, 0, byteCount);
		return buffer.getString(0, byteCount);
	}

	private static function ReadFully(input:Input, buffer:Bytes, offset:Int, length:Int):Void 
	{
		while (length > 0) 
		{
			var count:Int = input.readBytes(buffer, offset, length);
			if (count <= 0) throw "End of stream exception";
			offset += count;
			length -= count;
		}
	}
}

class Vertices 
{
	public var bones:Array<Int>;
	public var vertices:Vector<Float>;
	
	public function new()
	{
		
	}
}

class RGBA
{
	public var r:Int = 0;
	public var g:Int = 0;
	public var b:Int = 0;
	public var a:Int = 0;
	
	public function new()
	{
		
	}
	
	public inline function set(r:Int, g:Int, b:Int, a:Int)
	{
		this.r = r;
		this.g = g;
		this.b = b;
		this.a = a;
	}
}