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

import haxe.DynamicAccess;
import haxe.Json;
import haxe.ds.Vector;
import spine.Skin;
import spine.SlotData;
import spine.TransformConstraintData;
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
import spine.data.TAnimation;
import spine.data.TAnimation.IkConstraintTimeLineValue;
import spine.data.TAnimation.TAnimationData;
import spine.data.TAnimation.TAttachmentTimeLineValue;
import spine.data.TAnimation.TColorTimeLineValue;
import spine.data.TAnimation.TDeformTimeLineValue;
import spine.data.TAnimation.TDrawOrderOffset;
import spine.data.TAnimation.TDrawOrderTimeLineValue;
import spine.data.TAnimation.TEventTimeLineValue;
import spine.data.TAnimation.TPathConstraintMixTimeLineValue;
import spine.data.TAnimation.TPathConstraintTimeLineValue;
import spine.data.TAnimation.TRotateTimeLineValue;
import spine.data.TAnimation.TTranslateTimeLineValue;
import spine.data.TAnimation.TransformConstraintTimeLineValue;
import spine.data.TAttachment;
import spine.data.TEvent;
import spine.data.TEvent.TEvents;
import spine.data.TSkeleton;
import spine.data.TSkins;
import spine.data.TSpineData;

class SkeletonJson
{
	public var attachmentLoader: AttachmentLoader;
	public var scale: Float = 1;
	
	private var linkedMeshes: Array<LinkedMesh>;

	public function new(attachmentLoader: AttachmentLoader = null)
	{
		this.attachmentLoader = attachmentLoader;
		
		linkedMeshes = [];
	}

	public function readSkeletonData(object: String, name: String = null): SkeletonData
	{
		if (object == null)
		{
			throw "object cannot be null.";
		}

		var root: TSpineData = Json.parse( Std.string(object) );
		
		var skeletonData: SkeletonData = new SkeletonData();
		skeletonData.name = name;

		// Skeleton.
		var skeletonMap: TSkeleton = root.skeleton;
		if (skeletonMap != null) 
		{
			skeletonData.hash = skeletonMap.hash;
			skeletonData.version = skeletonMap.spine;
			skeletonData.width = skeletonMap.width.or( 0.0 );
			skeletonData.height = skeletonMap.height.or( 0.0 );
			skeletonData.fps = skeletonMap.fps.or(0.0);
			skeletonData.imagesPath = skeletonMap.images;
		}  
		
		// Bones.
		var boneData: BoneData;
		for (boneMap in root.bones)
		{
			var parent: BoneData = null;
			var parentName: String = boneMap.parent;
			if (parentName != null)
			{
				parent = skeletonData.findBone(parentName);
				if (parent == null)
					throw 'Parent bone not found: ${parentName}';
			}
			
			boneData = new BoneData(skeletonData.bones.length, boneMap.name, parent);
			boneData.length = boneMap.length.or( 0.0 ) * scale;
			boneData.x = boneMap.x.or( 0.0 ) * scale;
			boneData.y = boneMap.y.or( 0.0 ) * scale;
			boneData.rotation = boneMap.rotation.or( 0.0 );
			boneData.scaleX = boneMap.scaleX.or( 1.0 );
			boneData.scaleY = boneMap.scaleY.or( 1.0 );
			boneData.shearX = boneMap.shearX.or( 0.0 );
			boneData.shearY = boneMap.shearY.or( 0.0 );
			boneData.transformMode = boneMap.transform.or( "normal" );
			
			skeletonData.bones.push(boneData);
		}  
		
		// Slots.
		if( root.slots != null)
			for (slotMap in root.slots)
			{
				var slotName: String = slotMap.name;
				var boneName: String = slotMap.bone;
				boneData = skeletonData.findBone(boneName);
				if (boneData == null)
					throw 'Slot bone not found: ${boneName}';
				
				var slotData: SlotData = new SlotData(skeletonData.slots.length, slotName, boneData);

				var color: String = slotMap.color;
				if (color != null) 
				{
					slotData.r = toColor(color, 0);
					slotData.g = toColor(color, 1);
					slotData.b = toColor(color, 2);
					slotData.a = toColor(color, 3);
				}

				slotData.attachmentName = slotMap.attachment;
				slotData.blendMode = slotMap.blend.or( 0 );
				skeletonData.slots.push(slotData);
			}  
		
		// IK constraints.
		if( root.ik != null)
			for (constraintMap in root.ik)
			{
				var ikConstraintData: IkConstraintData = new IkConstraintData(constraintMap.name);
				ikConstraintData.order = constraintMap.order.or( 0.0 );
				
				for (boneName in constraintMap.bones)
				{
					var bone: BoneData = skeletonData.findBone(boneName);
					if (bone == null)
						throw 'IK constraint bone not found: ${boneName}';
					
					ikConstraintData.bones.push(bone);
				}

				ikConstraintData.target = skeletonData.findBone( constraintMap.target );
				if ( ikConstraintData.target == null )
					throw 'Target bone not found: ${constraintMap.target}';

				ikConstraintData.bendDirection = constraintMap.bendPositive.or( true ) ? 1 : -1;
				ikConstraintData.mix = constraintMap.mix.or( 1.0 );

				skeletonData.ikConstraints.push(ikConstraintData);
			}  
		
		// Transform constraints.
		if( root.transform != null)
			for (constraintMap in root.transform)
			{
				var transformConstraintData: TransformConstraintData = new TransformConstraintData(constraintMap.name);
				transformConstraintData.order = constraintMap.order.or( 0.0 );
				
				for (boneName in constraintMap.bones)
				{
					var bone = skeletonData.findBone(boneName);
					if (bone == null)
						throw 'Transform constraint bone not found: ${boneName}';
					
					transformConstraintData.bones.push(bone);
				}

				transformConstraintData.target = skeletonData.findBone(constraintMap.target);
				if (transformConstraintData.target == null)
					throw 'Target bone not found: ${constraintMap.target}';

				transformConstraintData.offsetRotation = constraintMap.rotation.or( 0.0 );
				transformConstraintData.offsetX = constraintMap.x.or( 0.0 ) * scale;
				transformConstraintData.offsetY = constraintMap.y.or( 0.0 ) * scale;
				transformConstraintData.offsetScaleX = constraintMap.scaleX.or( 0.0 );
				transformConstraintData.offsetScaleY = constraintMap.scaleY.or( 0.0 );
				transformConstraintData.offsetShearY = constraintMap.shearY.or( 0.0 );

				transformConstraintData.rotateMix = constraintMap.rotateMix.or( 1.0 );
				transformConstraintData.translateMix = constraintMap.translateMix.or( 1.0 );
				transformConstraintData.scaleMix = constraintMap.scaleMix.or( 1.0 );
				transformConstraintData.shearMix = constraintMap.shearMix.or( 1.0 );

				skeletonData.transformConstraints.push(transformConstraintData);
			}
		
		// Path constraints.
		if( root.path != null)
			for (constraintMap in root.path)
			{
				var pathConstraintData: PathConstraintData = new PathConstraintData(constraintMap.name);
				pathConstraintData.order = constraintMap.order.or( 0.0 );
				
				for (boneName in constraintMap.bones)
				{
					var bone = skeletonData.findBone(boneName);
					if (bone == null)
						throw 'Path constraint bone not found: ${boneName}';
						
					pathConstraintData.bones.push(bone);
				}

				pathConstraintData.target = skeletonData.findSlot(constraintMap.target);
				if (pathConstraintData.target == null)
					throw 'Path target slot not found: ${constraintMap.target}';

				pathConstraintData.positionMode = constraintMap.positionMode.or( "percent" );
				pathConstraintData.spacingMode = constraintMap.spacingMode.or( "length" );
				pathConstraintData.rotateMode = constraintMap.rotateMode.or( "tangent" );
				
				pathConstraintData.offsetRotation = constraintMap.rotation.or( 0.0 );
				pathConstraintData.position = constraintMap.position.or( 0.0 );
				if (pathConstraintData.positionMode == FIXED) pathConstraintData.position *= scale;
				pathConstraintData.spacing = constraintMap.spacing.or( 0.0 );
				if (pathConstraintData.spacingMode == LENGTH || pathConstraintData.spacingMode == FIXED) pathConstraintData.spacing *= scale;
				pathConstraintData.rotateMix = constraintMap.rotateMix.or( 1.0 );
				pathConstraintData.translateMix = constraintMap.translateMix.or( 1.0 );

				skeletonData.pathConstraints.push(pathConstraintData);
			}
		
		// Skins.
		var skins: TSkins = root.skins;
		if( skins != null )
			for (skinName in skins.keys())
			{
				var skinMap: TSkinSlots = skins[ skinName ];
				var skin: Skin = new Skin(skinName);
				for (slotName in skinMap.keys())
				{
					var slotIndex: Int = skeletonData.findSlotIndex( slotName );
					var slotEntry: TSkinSlotAttachments = skinMap[slotName];
					for (attachmentName in slotEntry.keys())
					{
						var attachment: Attachment = readAttachment(slotEntry[attachmentName], skin, slotIndex, attachmentName);
						if (attachment != null) 
							skin.addAttachment(slotIndex, attachmentName, attachment);
					}
				}
				
				skeletonData.skins[skeletonData.skins.length] = skin;
				if (skin.name == "default") 
					skeletonData.defaultSkin = skin;
			}  
		
		// Linked meshes.  
		var linkedMeshes: Array<LinkedMesh> = this.linkedMeshes;
		for (linkedMesh in linkedMeshes)
		{
			var parentSkin: Skin = (linkedMesh.skin == null) ? skeletonData.defaultSkin : skeletonData.findSkin(linkedMesh.skin);
			if (parentSkin == null)
				throw 'Skin not found: ${linkedMesh.skin}';
			
			var parentMesh: Attachment = parentSkin.getAttachment(linkedMesh.slotIndex, linkedMesh.parent);
			if (parentMesh == null)
				throw 'Parent mesh not found: ${linkedMesh.parent}';
			
			linkedMesh.mesh.parentMesh = cast parentMesh;
			linkedMesh.mesh.updateUVs();
		}
		linkedMeshes = [];

		// Events.
		var events: TEvents = root.events;
		if (events != null) 
			for (eventName in events.keys())
			{
				var eventMap: TEvent = events[eventName];
				var eventData: EventData = new EventData(eventName);
				eventData.intValue = eventMap.int.or( 0 );
				eventData.floatValue = eventMap.float.or( 0.0 );
				eventData.stringValue = eventMap.string.or( "" );
				skeletonData.events.push(eventData);
			} 
		
		// Animations.  
		var animations: DynamicAccess<TAnimationData> = root.animations;
		if( animations != null)
			for (animationName in animations.keys())
				readAnimation(animations[animationName], animationName, skeletonData);

		return skeletonData;
	}

	private function readAttachment(map: TAttachment, skin: Skin, slotIndex: Int, name: String): Attachment
	{
		name = map.name.or( name );

		var type: AttachmentType = map.type.or( "region" );

		var scale: Float = this.scale;
		var color: String;
		
		switch ( type )
		{
			case REGION:
				var region: RegionAttachment = attachmentLoader.newRegionAttachment(skin, name, map.path.or( name ));
				if (region == null)
					return null;
				
				region.path = map.path.or( name );
				region.x = map.x.or( 0.0 ) * scale;
				region.y = map.y.or( 0.0 ) * scale;
				region.scaleX = map.scaleX.or( 1.0 );
				region.scaleY = map.scaleY.or( 1.0 );
				region.rotation = map.rotation.or( 0.0 );
				region.width = map.width.or( 0.0 ) * scale;
				region.height = map.height.or( 0.0 ) * scale;
				color = map.color;
				if (color != null) 
				{
					region.r = toColor(color, 0);
					region.g = toColor(color, 1);
					region.b = toColor(color, 2);
					region.a = toColor(color, 3);
				}
				region.updateOffset();
				return region;
				
			case MESH | LINKEDMESH:
				var mesh: MeshAttachment = attachmentLoader.newMeshAttachment(skin, name, map.path.or( name ));
				if (mesh == null)
					return null;
				
				mesh.path = map.path.or( name );
				color = map.color;
				if (color != null) 
				{
					mesh.r = toColor(color, 0);
					mesh.g = toColor(color, 1);
					mesh.b = toColor(color, 2);
					mesh.a = toColor(color, 3);
				}

				mesh.width = map.width.or( 0.0 ) * scale;
				mesh.height = map.height.or( 0.0 ) * scale;

				if (map.parent != null) 
				{
					mesh.inheritDeform = map.deform.or( true );
					linkedMeshes.push(new LinkedMesh(mesh, map.skin, slotIndex, map.parent));
					return mesh;
				}

				var uvs = getFloatArray(map.uvs, 1);
				readVertices(map, mesh, uvs.length);
				mesh.triangles = map.triangles.copy();
				mesh.regionUVs = uvs;
				mesh.updateUVs();

				mesh.hullLength = map.hull.or ( 0 ) * 2;
				if (map.edges != null)
					mesh.edges = map.edges.copy();
				
				return mesh;
			
			case BOUNDINGBOX:
				var box: BoundingBoxAttachment = attachmentLoader.newBoundingBoxAttachment(skin, name);
				if (box == null)
					return null;
				
				readVertices(map, box, (map.vertexCount.or( 0 ) << 1) );
				return box;
			
			case PATH:
				var path: PathAttachment = attachmentLoader.newPathAttachment(skin, name);
				if (path == null)
					return null;
				
				path.closed = map.closed.or( false );
				path.constantSpeed = map.constantSpeed.or( true );

				var vertexCount: Int = map.vertexCount.or( 0 );
				readVertices(map, path, vertexCount << 1);

				path.lengths = getFloatArray(map.lengths, scale);
				return path;
		}

		return null;
	}

	private function readVertices(map: TAttachment, attachment: VertexAttachment, verticesLength: Int): Void
	{
		attachment.worldVerticesLength = verticesLength;
		var vertices = getFloatArray(map.vertices, 1.0);
		if (verticesLength == vertices.length) 
		{
			if (scale != 1) 
				for (i in 0...vertices.length)
					vertices[i] *= scale;
			
			attachment.vertices = vertices;
			return;
		}

		var weights: Array<Float> = [];
		var bones: Array<Int> = [];
		
		var i: Int = 0;
		while (i < vertices.length)
		{
			var boneCount: Int = Math.floor(vertices[i++]);
			bones.push(boneCount);
			var nn: Int = i + boneCount * 4;
			while (i < nn)
			{
				bones.push( Math.floor(vertices[i]) );
				weights.push(vertices[i + 1] * scale);
				weights.push(vertices[i + 2] * scale);
				weights.push(vertices[i + 3]);
				i += 4;
			}
		}
		attachment.bones = bones;
		attachment.vertices = getFloatArray(weights, 1);
	}

	private function readAnimation(map: TAnimationData, name: String, skeletonData: SkeletonData): Void
	{
		var scale: Float = this.scale;
		var timelines: Array<Timeline> = [];
		var duration: Float = 0;

		var slotIndex: Int;
		var slotName: String;
		var values: Array<TTimeLineValue>;
		var valueMap: Dynamic;
		var frameIndex: Int;
		var i: Int;
		var timelineName: String;

		var slots: DynamicAccess<TAnimation> = map.slots;
		for (slotName in slots.keys())
		{
			var slotMap: TAnimation = slots[slotName];
			slotIndex = skeletonData.findSlotIndex(slotName);
			
			for (timelineName in slotMap.keys())
			{
				values = slotMap[timelineName];
				if (timelineName == "color") 
				{
					var colorTimeline: ColorTimeline = new ColorTimeline( values.length );
					colorTimeline.slotIndex = slotIndex;

					frameIndex = 0;
					for (valueMap in values)
					{
						var colorValue: TColorTimeLineValue = cast valueMap;
						var color: String = colorValue.color;
						var r: Float = toColor(color, 0);
						var g: Float = toColor(color, 1);
						var b: Float = toColor(color, 2);
						var a: Float = toColor(color, 3);
						colorTimeline.setFrame(frameIndex, colorValue.time, r, g, b, a);
						readCurve(colorValue, colorTimeline, frameIndex);
						frameIndex++;
					}
					
					timelines[timelines.length] = colorTimeline;
					duration = Math.max(duration, colorTimeline.frames[(colorTimeline.frameCount - 1) * ColorTimeline.ENTRIES]);
				}
				else if (timelineName == "attachment") 
				{
					var attachmentTimeline: AttachmentTimeline = new AttachmentTimeline( values.length );
					attachmentTimeline.slotIndex = slotIndex;

					frameIndex = 0;
					for (valueMap in values)
					{
						var attachmentValue: TAttachmentTimeLineValue = cast valueMap;
						attachmentTimeline.setFrame(frameIndex++, attachmentValue.time, attachmentValue.name);
					}
						
					timelines[timelines.length] = attachmentTimeline;
					duration = Math.max(duration, attachmentTimeline.frames[attachmentTimeline.frameCount - 1]);
				}
				else 
					throw 'Invalid timeline type for a slot: ${timelineName} (${slotName})';
			}
		}

		var bones: DynamicAccess<TAnimation> = map.bones;
		for (boneName in bones.keys())
		{
			var boneIndex: Int = skeletonData.findBoneIndex(boneName);
			if (boneIndex == -1)
				throw 'Bone not found: ${boneName}';
			
			var boneMap: TAnimation = bones[boneName];

			for (timelineName in boneMap.keys())
			{
				values = boneMap[timelineName];
				if (timelineName == "rotate") 
				{
					var rotateTimeline: RotateTimeline = new RotateTimeline(values.length);
					rotateTimeline.boneIndex = boneIndex;

					frameIndex = 0;
					for (valueMap in values)
					{
						var rotateValue: TRotateTimeLineValue = cast valueMap;
						rotateTimeline.setFrame(frameIndex, rotateValue.time, rotateValue.angle);
						readCurve(rotateValue, rotateTimeline, frameIndex);
						frameIndex++;
					}
					timelines[timelines.length] = rotateTimeline;
					duration = Math.max(duration, rotateTimeline.frames[(rotateTimeline.frameCount - 1) * RotateTimeline.ENTRIES]);
				}
				else if (timelineName == "translate" || timelineName == "scale" || timelineName == "shear") 
				{
					var translateTimeline: TranslateTimeline;
					var timelineScale: Float = 1.0;
					if (timelineName == "scale") 
						translateTimeline = new ScaleTimeline(values.length)
					else if (timelineName == "shear") 
						translateTimeline = new ShearTimeline(values.length)
					else 
					{
						translateTimeline = new TranslateTimeline(values.length);
						timelineScale = scale;
					}
					translateTimeline.boneIndex = boneIndex;

					frameIndex = 0;
					for (valueMap in values)
					{
						var translateValue: TTranslateTimeLineValue = cast valueMap;
						var x: Float = translateValue.x.or( 0.0 ) * timelineScale;
						var y: Float = translateValue.y.or( 0.0 ) * timelineScale;
						translateTimeline.setFrame(frameIndex, translateValue.time, x, y);
						readCurve(translateValue, translateTimeline, frameIndex);
						frameIndex++;
					}
					timelines[timelines.length] = translateTimeline;
					duration = Math.max(duration, translateTimeline.frames[(translateTimeline.frameCount - 1) * TranslateTimeline.ENTRIES]);
				}
				else 
					throw 'Invalid timeline type for a bone: ${timelineName} (${boneName})';
			}
		}

		var ikMap: TAnimation = Reflect.field(map, "ik");
		for (ikConstraintName in ikMap.keys())
		{
			var ikConstraint: IkConstraintData = skeletonData.findIkConstraint(ikConstraintName);
			values = ikMap[ikConstraintName];
			var ikTimeline: IkConstraintTimeline = new IkConstraintTimeline(values.length);
			ikTimeline.ikConstraintIndex = skeletonData.ikConstraints.indexOf(ikConstraint);
			frameIndex = 0;
			for (valueMap in values)
			{
				var ikConstraintValue: IkConstraintTimeLineValue = cast valueMap;
				var mix: Float = ikConstraintValue.mix.or( 1.0 );
				var bendDirection: Int = (ikConstraintValue.bendPositive != null) ? 1 : -1;
				ikTimeline.setFrame(frameIndex, ikConstraintValue.time, mix, bendDirection);
				readCurve(ikConstraintValue, ikTimeline, frameIndex);
				frameIndex++;
			}
			timelines[timelines.length] = ikTimeline;
			duration = Math.max(duration, ikTimeline.frames[(ikTimeline.frameCount - 1) * IkConstraintTimeline.ENTRIES]);
		}

		var transformMap: TAnimation = map.transform;
		for (transformName in transformMap.keys())
		{
			var transformConstraint: TransformConstraintData = skeletonData.findTransformConstraint(transformName);
			values = transformMap[transformName];
			var transformTimeline: TransformConstraintTimeline = new TransformConstraintTimeline(values.length);
			transformTimeline.transformConstraintIndex = skeletonData.transformConstraints.indexOf(transformConstraint);
			frameIndex = 0;
			for (valueMap in values)
			{
				var transformConstraintValue: TransformConstraintTimeLineValue = cast valueMap;
				var rotateMix: Float = transformConstraintValue.rotateMix.or( 1.0 );
				var translateMix: Float = transformConstraintValue.translateMix.or( 1.0 );
				var scaleMix: Float = transformConstraintValue.scaleMix.or( 1.0 );
				var shearMix: Float = transformConstraintValue.shearMix.or( 1.0 );
				transformTimeline.setFrame(frameIndex, transformConstraintValue.time, rotateMix, translateMix, scaleMix, shearMix);
				readCurve(transformConstraintValue, transformTimeline, frameIndex);
				frameIndex++;
			}
			timelines.push(transformTimeline);
			duration = Math.max(duration, transformTimeline.frames[(transformTimeline.frameCount - 1) * TransformConstraintTimeline.ENTRIES]);
		}  
		
		// Path constraint timelines.
		var paths: DynamicAccess<TAnimation> = map.paths;
		for (pathName in paths.keys())
		{
			var index: Int = skeletonData.findPathConstraintIndex(pathName);
			if (index == -1)
				throw 'Path constraint not found: ${pathName}';
				
			var data: PathConstraintData = skeletonData.pathConstraints[index];

			var pathMap: TAnimation = paths[pathName];
			for (timelineName in pathMap.keys())
			{
				values = pathMap[timelineName];

				if (timelineName == "position" || timelineName == "spacing") 
				{
					var pathTimeline: PathConstraintPositionTimeline;
					var timelineScale: Float = 1.0;
					if (timelineName == "spacing") 
					{
						pathTimeline = new PathConstraintSpacingTimeline(values.length);
						if (data.spacingMode == LENGTH || data.spacingMode == FIXED)
							timelineScale = scale;
					}
					else 
					{
						pathTimeline = new PathConstraintPositionTimeline(values.length);
						if (data.positionMode == FIXED)
							timelineScale = scale;
					}
					pathTimeline.pathConstraintIndex = index;
					frameIndex = 0;
					for (valueMap in values)
					{
						var pathConstraintValue: TPathConstraintTimeLineValue = cast valueMap;
						var value: Float = (timelineName == "position") ? pathConstraintValue.position.or( 0.0 ) : pathConstraintValue.spacing.or( 0.0 );
						pathTimeline.setFrame(frameIndex, pathConstraintValue.time, value * timelineScale);
						readCurve(pathConstraintValue, pathTimeline, frameIndex);
						frameIndex++;
					}
					timelines.push(pathTimeline);
					duration = Math.max(duration, pathTimeline.frames[(pathTimeline.frameCount - 1) * PathConstraintPositionTimeline.ENTRIES]);
				}
				else if (timelineName == "mix") 
				{
					var pathMixTimeline: PathConstraintMixTimeline = new PathConstraintMixTimeline(values.length);
					pathMixTimeline.pathConstraintIndex = index;
					frameIndex = 0;
					for (valueMap in values)
					{
						var pathConstraintMixValue: TPathConstraintMixTimeLineValue = cast valueMap;
						var rotateMix = pathConstraintMixValue.rotateMix.or( 1.0 );
						var translateMix = pathConstraintMixValue.translateMix.or( 1.0 );
						pathMixTimeline.setFrame(frameIndex, pathConstraintMixValue.time, rotateMix, translateMix);
						readCurve(pathConstraintMixValue, pathMixTimeline, frameIndex);
						frameIndex++;
					}
					timelines.push(pathMixTimeline);
					duration = Math.max(duration, pathMixTimeline.frames[(pathMixTimeline.frameCount - 1) * PathConstraintMixTimeline.ENTRIES]);
				}
			}
		}

		var deformMap: DynamicAccess<DynamicAccess<TAnimation>> = Reflect.field(map, "deform");
		for (skinName in deformMap.keys())
		{
			var skin: Skin = skeletonData.findSkin(skinName);
			var slotMap: DynamicAccess<TAnimation> = deformMap[skinName];
			for (slotName in slotMap.keys())
			{
				slotIndex = skeletonData.findSlotIndex(slotName);
				var timelineMap: TAnimation = slotMap[slotName];
				for (timelineName in timelineMap.keys())
				{
					values = timelineMap[timelineName];

					var attachment: VertexAttachment = Std.is(skin.getAttachment(slotIndex, timelineName), VertexAttachment) ? cast skin.getAttachment(slotIndex, timelineName) : null;
					if (attachment == null)
						throw 'Deform attachment not found: ${timelineName}';
					
					var weighted: Bool = attachment.bones != null;
					var vertices: Vector<Float> = attachment.vertices;
					var deformLength: Int = (weighted) ? Math.floor(vertices.length / 3 * 2) : vertices.length;

					var deformTimeline: DeformTimeline = new DeformTimeline(values.length);
					deformTimeline.slotIndex = slotIndex;
					deformTimeline.attachment = attachment;

					frameIndex = 0;
					for (valueMap in values)
					{
						var deformValue: TDeformTimeLineValue = cast valueMap;
						
						var deform: Vector<Float>;
						var verticesValue: Array<Float> = deformValue.vertices;
						if (verticesValue == null) 
							deform = (weighted) ? ArrayUtils.allocFloat(deformLength) : vertices;
						else 
						{
							deform = ArrayUtils.allocFloat(deformLength);
							var start: Int = Math.floor(deformValue.offset.or( 0.0 ));
							var temp: Vector<Float> = getFloatArray( verticesValue, 1.0 );
							
							for (i in 0...temp.length)
								deform[start + i] = temp[i];
							
							if (scale != 1) 
							{
								var n : Int = start + temp.length;
								for (i in start...n)
									deform[i] *= scale;
							}
							
							if (!weighted) 
								for (i in 0...deformLength)
									deform[i] += vertices[i];
						}

						deformTimeline.setFrame(frameIndex, deformValue.time, deform);
						readCurve(deformValue, deformTimeline, frameIndex);
						frameIndex++;
					}
					timelines[timelines.length] = deformTimeline;
					duration = Math.max(duration, deformTimeline.frames[deformTimeline.frameCount - 1]);
				}
			}
		}

		var drawOrderValues: TTimeLine= map.drawOrder;
		if (drawOrderValues == null)
			drawOrderValues = map.draworder;
		
		if (drawOrderValues != null) 
		{
			var drawOrderTimeline: DrawOrderTimeline = new DrawOrderTimeline(drawOrderValues.length);
			var slotCount: Int = skeletonData.slots.length;
			
			frameIndex = 0;
			for (drawOrderMap in drawOrderValues)
			{
				var drawOrderValue: TDrawOrderTimeLineValue = cast drawOrderMap;
				var drawOrder: Array<Int> = null;
				if (drawOrderValue.offsets != null) 
				{
					drawOrder = [];
					i = slotCount - 1;
					while (i >= 0)
					{
						drawOrder[i] = -1;
						i--;
					}
					
					var offsets: Array<TDrawOrderOffset> = drawOrderValue.offsets;
					var unchanged: Array<Int> = [];
					var originalIndex: Int = 0;
					var unchangedIndex: Int = 0;
					
					for (offsetMap in offsets)
					{
						slotIndex = skeletonData.findSlotIndex(offsetMap.slot);
						if (slotIndex == -1)
							throw 'Slot not found: ${offsetMap.slot}';  
							
						// Collect unchanged items.
						while (originalIndex != slotIndex)
							unchanged[unchangedIndex++] = originalIndex++;
						
						// Set changed items.
						drawOrder[originalIndex + offsetMap.offset] = originalIndex++;
					}  
					
					// Collect remaining unchanged items.
					while (originalIndex < slotCount)
						unchanged[unchangedIndex++] = originalIndex++;
					
					// Fill in unchanged items.
					i = slotCount - 1;
					while (i >= 0) 
					{ 
						if (drawOrder[i] == -1)
							drawOrder[i] = unchanged[--unchangedIndex];
						
						i--;
					}
				}
				drawOrderTimeline.setFrame(frameIndex++, drawOrderValue.time, drawOrder);
			}
			timelines[timelines.length] = drawOrderTimeline;
			duration = Math.max(duration, drawOrderTimeline.frames[drawOrderTimeline.frameCount - 1]);
		}

		var eventsMap: TTimeLine = map.events;
		if (eventsMap != null) 
		{
			var eventTimeline: EventTimeline = new EventTimeline(eventsMap.length);
			
			frameIndex = 0;
			for (eventMap in eventsMap)
			{
				var eventValue: TEventTimeLineValue = cast eventMap;
				
				var eventData: EventData = skeletonData.findEvent(eventValue.name);
				if (eventData == null)
					throw 'Event not found: ${eventValue.name}';
				
				var event: Event = new Event(eventValue.time, eventData);
				event.intValue = eventValue.int.or( eventData.intValue );
				event.floatValue = eventValue.float.or( eventData.floatValue );
				event.stringValue = eventValue.string.or( eventData.stringValue );
				eventTimeline.setFrame(frameIndex++, event);
			}
			timelines[timelines.length] = eventTimeline;
			duration = Math.max(duration, eventTimeline.frames[eventTimeline.frameCount - 1]);
		}

		skeletonData.animations[skeletonData.animations.length] = new Animation(name, timelines, duration);
	}

	private static function readCurve(map: TTimeLineValue, timeline: CurveTimeline, frameIndex: Int): Void
	{
		var curve = map.curve;
		if (curve == null)
			return;
			
		if ( Std.is(curve, String) && cast( curve, String ) == "stepped" ) 
			timeline.setStepped( frameIndex );
		else if ( Std.is( curve, Array) )
		{
			var array: Array<Float> = cast curve;
			timeline.setCurve(frameIndex, array[0], array[1], array[2], array[3]);
		}
		else
			throw 'Unknown curve type!';
	}
	
	//FIXME: may be problem with utf string length
	private static function toColor(hexString: String, colorIndex: Int): Float
	{
		if (hexString.length != 8)
			throw 'Color hexidecimal length must be 8, recieved: ${hexString}';
		
		return Std.parseInt( "0x" + hexString.substring(colorIndex * 2, colorIndex * 2 + 2) ) / 255;
	}

	private static function getFloatArray(raw: Array<Float>, scale: Float): Vector<Float>
	{
		var n: Int = raw.length;
		var result = ArrayUtils.allocFloat( n );
		
		if ( scale == 1 ) for (i in 0...n) result[i] = raw[i];
		else for (i in 0...n) result[i] = raw[i] * scale;
		
		return result;
	}
}

class LinkedMesh
{
	public var parent: String;
	public var skin: String;
	public var slotIndex: Int;
	public var mesh: MeshAttachment;

	@:allow(spine) private function new(mesh: MeshAttachment, skin: String, slotIndex: Int, parent: String)
	{
		this.mesh = mesh;
		this.skin = skin;
		this.slotIndex = slotIndex;
		this.parent = parent;
	}
}