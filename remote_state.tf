terraform {
  backend "s3" {
    bucket = "shopizer-remote-state-bucket"
    key    = "/shopizer/remote_state.tfstate"
    region = "ap-southeast-1"
  }
}