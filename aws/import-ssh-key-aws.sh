aws ec2 import-key-pair --key-name aws-specai-cmh --public-key-material "$(cat ~/keys/aws-specai-cmh.pub | base64 )"
