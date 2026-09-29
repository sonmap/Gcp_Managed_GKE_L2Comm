# 40-scheduler

Cloud Scheduler가 `wf-l2comm-gke-job` Workflow를 호출하도록 gcloud 명령어로 구성하는 단계입니다.

> `cloudscheduler.googleapis.com` API 활성화는 `terraform/10-network` 단계에서 처리합니다.

## 실행 흐름

```text
Cloud Scheduler
   -> Workflows Executions API
   -> wf-l2comm-gke-job
   -> GKE Kubernetes Job
   -> GKE Autopilot Pod
```

## 1. Scheduler Job 생성

아래 예시는 매일 오전 09:00(KST) 실행입니다. 필요 시 `--schedule` 값만 변경합니다.

```bash
gcloud scheduler jobs create http sch-l2comm-gke-job \
  --project=gcp-prod-edp-edge-509423 \
  --location=asia-northeast3 \
  --schedule="0 9 * * *" \
  --time-zone="Asia/Seoul" \
  --uri="https://workflowexecutions.googleapis.com/v1/projects/gcp-prod-edp-edge-509423/locations/asia-northeast3/workflows/wf-l2comm-gke-job/executions" \
  --http-method=POST \
  --oauth-service-account-email="sa-l2comm-workflow@gcp-prod-edp-edge-509423.iam.gserviceaccount.com" \
  --oauth-token-scope="https://www.googleapis.com/auth/cloud-platform" \
  --headers="Content-Type=application/json" \
  --message-body='{"argument":"{}"}'
```

## 2. 즉시 테스트 실행

스케줄 시간을 기다리지 않고 즉시 실행할 수 있습니다.

```bash
gcloud scheduler jobs run sch-l2comm-gke-job \
  --project=gcp-prod-edp-edge-509423 \
  --location=asia-northeast3
```

## 3. 상태 확인

```bash
gcloud scheduler jobs describe sch-l2comm-gke-job \
  --project=gcp-prod-edp-edge-509423 \
  --location=asia-northeast3
```

Workflow 실행 확인:

```bash
gcloud workflows executions list wf-l2comm-gke-job \
  --project=gcp-prod-edp-edge-509423 \
  --location=asia-northeast3 \
  --limit=10
```
