resource "random_id" "deployment" {
  byte_length = 4
  keepers = {
    backend_image = var.backend_image_tag
  }
}
