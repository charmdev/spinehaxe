package spine.attachments;

/**
 * ...
 * @author Zaphod
 */
class EmptyAttachmentLoader implements AttachmentLoader
{

	public function new() 
	{
		
	}
	
	public function newRegionAttachment(skin: Skin, name: String, path: String): RegionAttachment
	{
		var attachment: RegionAttachment = new RegionAttachment(name);
		return attachment;
	}

	public function newMeshAttachment(skin: Skin, name: String, path: String): MeshAttachment
	{
		var attachment: MeshAttachment = new MeshAttachment(name);
		return attachment;
	}

	public function newBoundingBoxAttachment(skin: Skin, name: String): BoundingBoxAttachment
	{
		return new BoundingBoxAttachment(name);
	}

	public function newPathAttachment(skin: Skin, name: String): PathAttachment
	{
		return new PathAttachment(name);
	}
}