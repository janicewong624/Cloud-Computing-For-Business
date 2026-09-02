# AWS Deployment — `library-resource-scheduling` (adapted from 老師's `event-ticketing` example)

這套 Terraform + GitHub Actions 是照老師給的 `infra.zip` 架構,改成對應你的
`library-resource-scheduling`(圖書館資源預約系統)專案。跟老師原版的差異:

| 項目 | 老師原版 | 這份改過的版本 |
|---|---|---|
| 資料庫名 | `event_ticketing_db` | `library_booking_db`(跟你的 `schema.sql`/`config.php` 一致) |
| DB 帳號 | `admin` | `aws_admin`(照你原本 console 筆記) |
| user-data 寫入的環境變數 | `S3_BUCKET` / `AWS_REGION` | `AWS_S3_BUCKET` / `AWS_S3_REGION`(照你 `config.php` 裡 `getenv()` 讀的名字) |
| S3 上傳方式 | 靠 Composer 裝 `aws/aws-sdk-php` | **不需要**,你的 `helpers.php` 已經自己刻好 SigV4 簽名直連 S3 API,少一個安裝步驟 |
| 有圖片欄位的資料表 | 只有 `events` | `rooms` / `equipment` / `books` 三張表都有 `image_url`,`seed-db.sh` 已改成逐一更新 |
| GitHub Actions workflow 檔案 | README 裡只有文字描述,沒附實際 `.yml` | 這份直接把 `ci.yml` / `build.yml` / `deploy.yml` / `db-init.yml` 四個檔案都寫出來了 |

架構本身(VPC 兩個 public + 兩個 private 子網路、三層 Security Group、RDS
private、Secrets Manager 存密碼、SSM 部署不用 SSH、S3 Gateway Endpoint 省
NAT 費、Target Tracking Scaling)完全比照老師的設計,這套設計已經解決了你
之前遇到的「It works! 預設頁面」問題根源(老師的版本靠 GitHub Actions 主動
把打包好的 zip 上傳 S3,再用 SSM 命令要 EC2 去抓,而不是讓 EC2 開機時去
git clone)。

## 檔案結構

```
your-repo/                          <- 你的 GitHub repo 根目錄
├── config.php, healthz.php, ...    <- 你原本的 app 檔案,留在根目錄
├── schema.sql
├── infra/                          <- 這次新增的資料夾
│   ├── modules/
│   │   ├── vpc/  security-groups/  s3/  secrets/  rds/  alb/  asg/
│   ├── envs/sandbox/
│   │   ├── main.tf  variables.tf  outputs.tf  providers.tf  backend.tf  terraform.tvars
│   ├── scripts/seed-db.sh
│   └── README.md                   <- 這份檔案
└── .github/workflows/
    ├── ci.yml
    ├── build.yml
    ├── deploy.yml
    └── db-init.yml
```

**重要假設**:`deploy.yml` 打包 app 程式碼時預設你的 PHP 檔案(`config.php`、
`healthz.php`、`schema.sql` 等)直接放在 **repo 根目錄**,不是放在子資料夾裡。
如果你的檔案其實放在像 `library-resource-scheduling/` 這樣的子資料夾裡,要把
`deploy.yml` 裡 `zip -r /tmp/library-booking-app.zip .` 那行的 `.` 改成那個
子資料夾路徑。

## 設定步驟

### 1. 一次性手動 bootstrap state bucket(在自己電腦跑,只需跑一次)

```bash
ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
STATE_BUCKET="assignment-tfstate-${ACCOUNT_ID}"

aws s3api create-bucket --bucket "$STATE_BUCKET" --region us-east-1
aws s3api put-bucket-versioning --bucket "$STATE_BUCKET" --versioning-configuration Status=Enabled
aws dynamodb create-table --table-name assignment-tf-lock \
  --attribute-definitions AttributeName=LockID,AttributeType=S \
  --key-schema AttributeName=LockID,KeyType=HASH \
  --billing-mode PAY_PER_REQUEST
```

然後打開 `infra/envs/sandbox/backend.tf`,把 `bucket` 那行改成你剛建的
`assignment-tfstate-<你的account id>`。

### 2. GitHub Secrets

Repo → Settings → Secrets and variables → Actions,加入 3 個(跟之前一樣,
Academy Lab 每次都要重新複製更新):

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `AWS_SESSION_TOKEN`

不需要再設 `db_password`,因為這版密碼是 Terraform 自己用
`random_password` 產生、直接存進 Secrets Manager,不會出現在任何地方讓你
手動輸入。

### 3. 部署順序

1. Actions 分頁 → **CI - Full Pipeline** → Run workflow → mode 選 `plan`,
   先確認要建立的資源清單正確(這步唯讀,不會動 AWS)。
2. mode 選 `deploy` → Run workflow — 這會先 apply 整套 infra(VPC/RDS/ALB/ASG
   全部建好),等實例透過 SSM 上線後,再把你的程式碼打包上傳 S3 並用 SSM
   推到每台實例上。
3. 資源建好、程式碼部署完之後,跑一次 **DB - Seed Database**(`db-init.yml`)
   把 `schema.sql` 灌進 RDS。之後重複跑是安全的,已經灌過會自動跳過。
4. 打開 `terraform output alb_dns_name` 印出的網址,確認網站正常。
5. 展示完 → mode 選 `destroy`,把資源全部關掉省額度。

## 跟你之前版本的差異提醒

- 這版**有開 NAT Gateway**(老師的設計),跟我們最早給你的版本(只靠 S3
  Gateway Endpoint,不開 NAT)不同。NAT 會持續計費,記得展示完就
  `destroy`。
- SSH 這次完全沒對外開放,只留 VPC 內部 CIDR 可連(給同 VPC 內的工具用),
  日常操作一律走 **SSM Session Manager**,不需要 keypair 也能連進實例。
