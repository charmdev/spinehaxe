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

import spine.attachments.Attachment;
import spine.attachments.AttachmentType;
import spine.attachments.PathAttachment;

class Skeleton
{
	public var data(get, never): SkeletonData;
	public var getUpdateCache(get, never): Array<Updatable>;
	public var rootBone(get, never): Bone;
	public var skin(get, set): Skin;
	public var skinName(get, set): String;

	public var bones: Array<Bone>;
	public var slots: Array<Slot>;
	public var drawOrder: Array<Slot>;
	public var ikConstraints: Array<IkConstraint>;
	public var transformConstraints: Array<TransformConstraint>;
	public var pathConstraints: Array<PathConstraint>;
	
	public var r: Float = 1;
	public var g: Float = 1;
	public var b: Float = 1;
	public var a: Float = 1;
	public var time: Float = 0;
	public var flipX: Bool;
	public var flipY: Bool;
	public var x: Float = 0;
	public var y: Float = 0;
	
	public function new(data : SkeletonData)
	{		
		if (data == null) 
			throw 'data cannot be null.';
		
		_data = data;

		bones = [];
		for (boneData in data.bones)
		{
			var bone: Bone;
			if (boneData.parent == null) 
				bone = new Bone(boneData, this, null)
			else 
			{
				var parent: Bone = bones[boneData.parent.index];
				bone = new Bone(boneData, this, parent);
				parent.children.push(bone);
			}
			bones.push(bone);
		}

		slots = [];
		drawOrder = [];
		for (slotData in data.slots)
		{
			var bone = bones[slotData.boneData.index];
			var slot: Slot = new Slot(slotData, bone);
			slots.push(slot);
			drawOrder[drawOrder.length] = slot;
		}

		ikConstraints = [];
		for (ikConstraintData in data.ikConstraints)
			ikConstraints.push(new IkConstraint(ikConstraintData, this));

		transformConstraints = [];
		for (transformConstraintData in data.transformConstraints)
			transformConstraints.push(new TransformConstraint(transformConstraintData, this));

		pathConstraints = [];
		for (pathConstraintData in data.pathConstraints)
			pathConstraints.push(new PathConstraint(pathConstraintData, this));

		updateCache();
	}

	/** Caches information about bones and constraints. Must be called if bones, constraints, or weighted path attachments are
	* added or removed. */
	public function updateCache(): Void
	{
		this._updateCache = [];
		var updateCache: Array<Updatable> = this._updateCache;
		//updateCache.length = 0;

		for (i in 0...bones.length)
			bones[i]._sorted = false;

		// IK first, lowest hierarchy depth first.
		var ikCount: Int = ikConstraints.length;
		var transformCount: Int = transformConstraints.length;
		var pathCount: Int = pathConstraints.length;
		var constraintCount: Int = ikCount + transformCount + pathCount;
		
		//outer
		for (i in 0...constraintCount) 
		{
			var outerContinue: Bool = false;
			
			for (ii in 0...ikCount) 
			{
				var ikConstraint: IkConstraint = ikConstraints[ii];
				if (ikConstraint.data.order == i)
				{
					sortIkConstraint(ikConstraint);
					outerContinue = true;
					break;
				}
			}
			
			if (outerContinue)
				continue;
			
			for (ii in 0...transformCount) 
			{
				var transformConstraint: TransformConstraint = transformConstraints[ii];
				if (transformConstraint.data.order == i) 
				{
					sortTransformConstraint(transformConstraint);
					outerContinue = true;
					break;
				}
			}
			
			if (outerContinue)
				continue;
			
			for (ii in 0...pathCount) 
			{
				var pathConstraint: PathConstraint = pathConstraints[ii];
				if (pathConstraint.data.order == i) 
				{
					sortPathConstraint(pathConstraint);
					outerContinue = true;
					break;
				}
			}
			
			if (outerContinue)
				continue;
		}
		
		var boneCount = bones.length;
		for (i in 0...boneCount)
			sortBone(bones[i]);
	}

	private function sortIkConstraint(constraint: IkConstraint): Void 
	{
		var target: Bone = constraint.target;
		sortBone(target);

		var constrained: Array<Bone> = constraint.bones;
		var parent: Bone = constrained[0];
		sortBone(parent);

		if (constrained.length > 1) 
		{
			var child: Bone = constrained[constrained.length - 1];
			if ( !(_updateCache.indexOf(child) > -1) )
				_updateCacheReset.push(child);
		}

		_updateCache.push(constraint);

		sortReset(parent.children);
		constrained[constrained.length - 1]._sorted = true;
	}

	private function sortPathConstraint(constraint: PathConstraint): Void 
	{
		var slot: Slot = constraint.target;
		var slotIndex: Int = slot.data.index;
		var slotBone: Bone = slot.bone;
		
		if (skin != null) 
			sortPathConstraintAttachment(skin, slotIndex, slotBone);
			
		if (data.defaultSkin != null && data.defaultSkin != skin)
			sortPathConstraintAttachment(data.defaultSkin, slotIndex, slotBone);
		
		var nn: Int = data.skins.length;		
		for (ii in 0...nn)
			sortPathConstraintAttachment(data.skins[ii], slotIndex, slotBone);

		var attachment: Attachment = slot.attachment;
		if (attachment.type == AttachmentType.PATH) 
			sortPathConstraintAttachment2(attachment, slotBone);

		var constrained: Array<Bone> = constraint.bones;
		var boneCount: Int = constrained.length;
		for (ii in 0...boneCount)
			sortBone(constrained[ii]);

		_updateCache.push(constraint);

		for (ii in 0...boneCount)
			sortReset(constrained[ii].children);
		for (ii in 0...boneCount)
			constrained[ii]._sorted = true;
	}
	
	private function sortTransformConstraint(constraint: TransformConstraint): Void 
	{
		sortBone(constraint.target);

		var constrained: Array<Bone> = constraint.bones;
		var boneCount: Int = constrained.length;
		for (ii in 0...boneCount)
			sortBone(constrained[ii]);

		_updateCache.push(constraint);

		for (ii in 0...boneCount)
			sortReset(constrained[ii].children);
		
		for (ii in 0...boneCount)
			constrained[ii]._sorted = true;
	}
	
	private function sortPathConstraintAttachment(skin: Skin, slotIndex: Int, slotBone: Bone): Void
	{
		var dict: Map<String, Attachment> = skin.attachments[slotIndex];
		if (dict == null)
			return;

		for (value in dict.iterator())
			sortPathConstraintAttachment2(value, slotBone);
	}

	private function sortPathConstraintAttachment2(attachment: Attachment, slotBone: Bone): Void
	{
		var pathAttachment: PathAttachment = attachment.type == AttachmentType.PATH ? cast attachment : null;
		if (pathAttachment == null)
			return;
		
		var pathBones: Array<Int> = pathAttachment.bones;
		if (pathBones == null) 
			sortBone(slotBone);
		else 
		{
			var bones: Array<Bone> = this.bones;
			var i: Int = 0;
			while (i < pathBones.length) 
			{
				var boneCount: Int = pathBones[i++];
				var n: Int = i + boneCount;
				while (i < n)
				{
					sortBone(bones[pathBones[i]]);
					i++;
				}
			}
		}
	}

	private function sortBone(bone: Bone): Void
	{
		if (bone._sorted)
			return;
		
		var parent: Bone = bone.parent;
		if (parent != null)
			sortBone(parent);
		
		bone._sorted = true;
		_updateCache.push(bone);
	}

	private function sortReset(bones: Array<Bone>): Void
	{
		for (i in 0...bones.length)
		{
			var bone: Bone = bones[i];
			if (bone._sorted)
				sortReset(bone.children);
			bone._sorted = false;
		}
	}

	/** Updates the world transform for each bone and applies constraints. */
	public function updateWorldTransform(): Void
	{
		var updateCacheReset: Array<Bone> = this._updateCacheReset;
		for (bone in updateCacheReset) 
		{
			bone.ax = bone.x;
			bone.ay = bone.y;
			bone.arotation = bone.rotation;
			bone.ascaleX = bone.scaleX;
			bone.ascaleY = bone.scaleY;
			bone.ashearX = bone.shearX;
			bone.ashearY = bone.shearY;
			bone.appliedValid = true;
		}
		
		for (updatable in _updateCache)
			updatable.update();
	}

	/** Sets the bones, constraints, and slots to their setup pose values. */
	public function setToSetupPose(): Void
	{
		setBonesToSetupPose();
		setSlotsToSetupPose();
	}

	/** Sets the bones and constraints to their setup pose values. */
	public function setBonesToSetupPose(): Void
	{
		for (bone in bones)
			bone.setToSetupPose();

		for (ikConstraint in ikConstraints)
		{
			ikConstraint.bendDirection = ikConstraint._data.bendDirection;
			ikConstraint.mix = ikConstraint._data.mix;
		}

		for (transformConstraint in transformConstraints)
		{
			transformConstraint.rotateMix = transformConstraint._data.rotateMix;
			transformConstraint.translateMix = transformConstraint._data.translateMix;
			transformConstraint.scaleMix = transformConstraint._data.scaleMix;
			transformConstraint.shearMix = transformConstraint._data.shearMix;
		}

		for (pathConstraint in pathConstraints)
		{
			pathConstraint.position = pathConstraint._data.position;
			pathConstraint.spacing = pathConstraint._data.spacing;
			pathConstraint.rotateMix = pathConstraint._data.rotateMix;
			pathConstraint.translateMix = pathConstraint._data.translateMix;
		}
	}

	public function setSlotsToSetupPose(): Void
	{
		var i: Int = 0;
		for (slot in slots)
		{
			drawOrder[i++] = slot;
			slot.setToSetupPose();
		}
	}

	/** @return May be null. */
	public function findBone(boneName: String): Bone
	{
		if (boneName == null) 
			throw 'boneName cannot be null.';

		for (bone in bones)
			if (bone._data._name == boneName)
				return bone;
		
		return null;
	}

	/** @return -1 if the bone was not found. */
	public function findBoneIndex(boneName: String): Int
	{	
		if (boneName == null) 
			throw 'boneName cannot be null.';
		
		var i: Int = 0;
		for (bone in bones)
		{
			if (bone._data._name == boneName)
				return i;
			
			i++;
		}
		return -1;
	}

	/** @return May be null. */
	public function findSlot(slotName: String): Slot
	{
		if (slotName == null) 
			throw 'slotName cannot be null.';
		
		for (slot in slots)
			if (slot._data._name == slotName)
				return slot;
		
		return null;
	}

	/** @return -1 if the bone was not found. */
	public function findSlotIndex(slotName: String): Int
	{
		if (slotName == null) 
			throw 'slotName cannot be null.';
		
		var i: Int = 0;
		for (slot in slots)
		{
			if (slot._data._name == slotName)
				return i;
			
			i++;
		}
		return -1;
	}

	/** @return May be null. */
	public function getAttachmentForSlotName(slotName: String, attachmentName: String): Attachment
	{
		return getAttachmentForSlotIndex(data.findSlotIndex(slotName), attachmentName);
	}

	/** @return May be null. */
	public function getAttachmentForSlotIndex(slotIndex : Int, attachmentName : String): Attachment
	{		
		if (attachmentName == null)
			throw 'attachmentName cannot be null.';
		
		if (skin != null) 
		{
			var attachment: Attachment = skin.getAttachment(slotIndex, attachmentName);
			if (attachment != null)
				return attachment;
		}
		
		if (data.defaultSkin != null)
			return data.defaultSkin.getAttachment(slotIndex, attachmentName);
		
		return null;
	}

	/** @param attachmentName May be null. */
	public function setAttachment(slotName: String, attachmentName: String): Void
	{		
		if (slotName == null)
			throw 'slotName cannot be null.';
		
		var i: Int = 0;
		for (slot in slots)
		{
			if (slot._data._name == slotName)
			{
				var attachment: Attachment = null;
				if (attachmentName != null)
				{
					attachment = getAttachmentForSlotIndex(i, attachmentName);
					if (attachment == null) 
						throw 'Attachment not found: ${attachmentName}, for slot: ${slotName}';
				}
				slot.attachment = attachment;
				return;
			}
			i++;
		}
		throw 'Slot not found: ${slotName}';
	}

	/** @return May be null. */
	public function findIkConstraint(constraintName: String): IkConstraint
	{		
		if (constraintName == null)
			throw 'constraintName cannot be null.';
		
		for (ikConstraint in ikConstraints)
			if (ikConstraint._data._name == constraintName)
				return ikConstraint;
		
		return null;
	}

	/** @return May be null. */
	public function findTransformConstraint(constraintName: String): TransformConstraint
	{		
		if (constraintName == null)
			throw 'constraintName cannot be null.';
		
		for (transformConstraint in transformConstraints)
			if (transformConstraint._data._name == constraintName)
				return transformConstraint;
		
		return null;
	}

	/** @return May be null. */
	public function findPathConstraint(constraintName: String): PathConstraint
	{
		if (constraintName == null)
			throw 'constraintName cannot be null.';
		
		for (pathConstraint in pathConstraints)
			if (pathConstraint._data._name == constraintName)
				return pathConstraint;
		
		return null;
	}

	public inline function update(delta: Float) : Void
	{
		time += delta;
	}

	public inline function toString() : String
	{
		return _data.name;
	}
	
	// getters / setters
	private inline function get_data(): SkeletonData return _data;
	private inline function get_getUpdateCache(): Array<Updatable> return _updateCache;
	private inline function get_rootBone() : Bone
	{
		if (bones.length == 0)
			return null;
		
		return bones[0];
	}
	private inline function get_skin(): Skin return _skin;

	/** @return May be null. */
	private inline function get_skinName(): String return _skin == null ? null : _skin._name;
	
	/** Sets the skin used to look up attachments before looking in the {@link SkeletonData#getDefaultSkin() default skin}. 
	* Attachments from the new skin are attached if the corresponding attachment from the old skin was attached. If there was 
	* no old skin, each slot's setup mode attachment is attached from the new skin.
	* @param newSkin May be null. */
	private function set_skin(newSkin: Skin): Skin
	{
		if (newSkin != null) 
		{
			if (skin != null) 
				newSkin.attachAll(this, skin)
			else 
			{
				var i: Int = 0;
				for (slot in slots)
				{
					var name: String = slot._data.attachmentName;
					if (name != null) 
					{
						var attachment: Attachment = newSkin.getAttachment(i, name);
						if (attachment != null)
							slot.attachment = attachment;
					}
					i++;
				}
			}
		}
		_skin = newSkin;
		return newSkin;
	}
	
	private inline function set_skinName(skinName: String): String
	{
		var skin: Skin = data.findSkin(skinName);
		if (skin == null)
			throw 'Skin not found: ${skinName}';
		
		this.skin = skin;
		return skinName;
	}

	@:allow(spine) private var _data : SkeletonData;
	private var _updateCache: Array<Updatable> = new Array<Updatable>();
	private var _updateCacheReset: Array<Bone> = new Array<Bone>();
	private var _skin : Skin;
}