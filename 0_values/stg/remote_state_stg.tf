terraform {
  backend "s3" {
    bucket = "shopizer-remote-state-bucket"
    key    = "shopizer/remote_state_stg.tfstate"
    region = "ap-southeast-1"
  }
}