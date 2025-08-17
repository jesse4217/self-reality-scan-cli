# Reality Capture 自動化

ヘルメット治療向けのスキャンアプリ、**Berry Scan**用の自動化スクリプトである.

## 環境構築

EC2上に動作できるように環境構築を行う.

### Step 1: AWS CLIのインストール

```bash
msiexec.exe /i https://awscli.amazonaws.com/AWSCLIV2.msi
```

```bash
aws configure list
aws configure
```
AWSの公式ドキュメントはこちら:

- [AWS CLI Installation Guide](https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2.html)

### Step 2: Pythonのセットアップ

パッケージの管理をしやすくするため、pythonの仮想環境で作業を行う:

今回はrealityCaptureEnvを環境の名前とすル。
```bash
python -m venv realityCaptureEnv
```

```bash
.\realityCaptureEnv\Scripts\activate
```

```bash
pip install -r requirements.txt
```
### Step 3: Reality Captureダウンロード

1. **launcherをダウンロード:**

   公式ウェブサイトからReality Captureをダウンロードする:
   - [Reality Capture Download Page](https://www.capturingreality.com/DownloadNow)

2. **CUDAセットアップ:**

   CUDA ToolKitをダウンロードする:
   - [CUDA ToolKit 11.8 Downloads](https://developer.nvidia.com/cuda-11-8-0-download-archive?target_os=Windows&target_arch=x86_64&target_version=10&target_type=exe_local)