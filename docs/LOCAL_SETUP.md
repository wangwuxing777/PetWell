# Application Local Setup

## 1) Prepare config
```bash
cp config/env.example config/local.env
bash scripts/verify_env.sh
```

## 2) Backend dependency
- App backend default: `http://127.0.0.1:8000`
- Merchant backend default: `http://127.0.0.1:8090`

Make sure both are running before end-to-end booking tests.

## 3) Run iOS app
- Open `PetWell.xcworkspace` in Xcode
- Build and run on simulator/device
