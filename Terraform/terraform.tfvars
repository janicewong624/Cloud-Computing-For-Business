aws_region = "us-east-1"

project_name = "library"
short_name   = "library"

# 去 https://whatismyip.com 查你自己的公網 IP，換掉下面這串，/32 一定要保留
my_ip_cidr = "1.2.3.4/32"

# 換成你在 EC2 Console 建的 Key Pair 名字
key_pair_name = "your-key-pair-name"

# 換成你自己的 GitHub repo
git_repo_url = "https://github.com/janicewong624/Cloud-Computing-For-Business.git"
app_subdir   = "library-resource-scheduling"

# 自己設一個資料庫密碼（至少8位，包含大小寫字母跟數字，不要用 @ / " $ 這種特殊符號）
db_username = "admin"
db_password = "admin1234"
db_name     = "library_booking_db"

# 去 AWS Academy 的 AWS Details 標籤確認，通常是這個名字
lab_instance_profile_name = "LabInstanceProfile"

web_instance_type     = "t3.micro"
app_instance_type     = "t3.micro"
bastion_instance_type = "t3.micro"
db_instance_class     = "db.t3.micro"

asg_min_size         = 1
asg_desired_capacity = 2
asg_max_size         = 4