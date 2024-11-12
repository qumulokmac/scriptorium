################################################################################
#
# File: ./modules/ec2_instances/data_sources.tf data_sources.tf 
#
################################################################################

# data "aws_ssm_parameter" "admin_password" {
#   name            = "/grumpquat/windows/admin_password"
#   with_decryption = true
# }

data "aws_s3_object" "ubuntu_userdata_script" {
  bucket = "bucket-of-bytes"
  key    = "scripts/alg_ud.sh"
}

data "aws_s3_object" "windows_userdata_script" {
  bucket = "bucket-of-bytes"
  key    = "scripts/grumpquat-windows-userdata.ps1"
  depends_on = [aws_iam_instance_profile.ec2_instance_profile]

}
