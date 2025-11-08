
# Healthcare SAM Starter (Minimal)

This is a minimal, working AWS SAM project that deploys:
- A REST API Gateway stage (`/prod`)
- One Lambda function wired to `POST /registration`
- CORS enabled for browser calls

## Prereqs (run once on your laptop or Cloud9)
1) Install and configure the AWS CLI:
   https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
   ```bash
   aws configure
   # Set your account's access key, secret, region (e.g., eu-west-3) and output json
   ```
2) Install the AWS SAM CLI:
   https://docs.aws.amazon.com/serverless-application-model/latest/developerguide/install-sam-cli.html

## Deploy
From this folder:
```bash
sam build
sam deploy --guided
```
- Choose a stack name (e.g., healthcare-mvp)
- Accept the defaults and let SAM create a deployment bucket
- After deploy, SAM will print `ApiBaseUrl` like:
  https://abc123.execute-api.eu-west-3.amazonaws.com/prod

## Test from your terminal
```bash
API="https://<api-id>.execute-api.<region>.amazonaws.com/prod/registration"
curl -i -X POST "$API" -H "Content-Type: application/json" -d '{"patientId":"p1","name":"Raja"}'
```

Expect HTTP/1.1 200 and a JSON body.

## Wire the Frontend
Give your teammate this full URL including `/registration`, e.g.:
```
https://abc123.execute-api.eu-west-3.amazonaws.com/prod/registration
```
In their `index.html`, call this endpoint with `fetch`.

## Troubleshooting
- 502: Check CloudWatch Logs for the Lambda; handler must return the exact JSON shape from `app.py`.
- CORS error: Ensure your request is `POST` and your API has CORS (already enabled here). Also ensure your Lambda returns the CORS headers (done in `_res()`).
- 403/404: Verify you used the full URL with `/prod/registration`.
