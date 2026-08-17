require "fileutils"
require "mini_magick"

class RoomPhoto < ApplicationRecord
  belongs_to :room

  scope :ordered, -> { order(:position) }

  PHOTOS_DIR = File.join(APP_ROOT, "public", "uploads", "photos")

  def self.attach_file(room, source_path, original_name, position: nil)
    ext = File.extname(original_name.to_s).presence || ".jpg"
    base = "room_#{room.id}_#{SecureRandom.hex(6)}"
    filename = "#{base}#{ext}"
    thumb_filename = "#{base}_thumb.jpg"

    FileUtils.mkdir_p(PHOTOS_DIR)
    FileUtils.cp(source_path, File.join(PHOTOS_DIR, filename))

    thumb_ok = ImageTools.resize_to_fill(
      File.join(PHOTOS_DIR, filename),
      File.join(PHOTOS_DIR, thumb_filename),
      640, 400
    )

    create!(room: room, filename: filename,
            thumb_filename: thumb_ok ? thumb_filename : nil,
            position: position || (room.photos.count + 1))
  end

  def url
    "/uploads/photos/#{filename}"
  end

  def thumb_url
    "/uploads/photos/#{thumb_filename || filename}"
  end

  def file_path
    File.join(PHOTOS_DIR, filename)
  end

  def thumb_path
    thumb_filename && File.join(PHOTOS_DIR, thumb_filename)
  end

  def destroy_with_files!
    File.delete(file_path) if file_path && File.exist?(file_path)
    File.delete(thumb_path) if thumb_path && File.exist?(thumb_path)
    destroy!
  end
end

module ImageTools
  def self.resize_to_fill(source, destination, width, height)
    image = MiniMagick::Image.open(source)
    image.combine_options do |cmd|
      cmd.resize "#{width}x#{height}^"
      cmd.gravity "center"
      cmd.extent "#{width}x#{height}"
    end
    image.quality 85
    image.write(destination)
    true
  rescue MiniMagick::Error, MiniMagick::Invalid
    false
  end
end
