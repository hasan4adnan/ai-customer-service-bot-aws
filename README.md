## 🤖 AI Customer Service Bot

An AI-powered customer service assistant built on AWS Bedrock (Claude 3.5 Sonnet), fully serverless, scalable, and cost-efficient.

This bot can handle customer queries, store conversation history, and send alerts when issues occur — all using AWS managed services.

## 🚀 Features
- **Natural Conversations** powered by Claude 3.5 Sonnet via Amazon Bedrock
- **Serverless Backend** with AWS Lambda + API Gateway
- **Persistent Conversation History** using DynamoDB
- **Real-time Monitoring** with CloudWatch
- **Error Notifications** via SNS (Email/SMS)
- **Modern Frontend** built with React.js for a seamless chat experience

## 🏗️ Architecture
```
User (React Web App)
        │
        ▼
API Gateway  ──►  AWS Lambda  ──►  DynamoDB (conversation_history)
        │                │
        │                ├─► Amazon Bedrock (Claude 3.5 Sonnet)
        │                ├─► SNS (Error Notifications)
        │                └─► CloudWatch (Logs & Alarms)
        ▼
User Interface (Chat Response)
```

- **Frontend**: React.js (simple chat UI)
- **API Layer**: API Gateway (with CORS enabled)
- **Logic Layer**: Lambda (business logic, Bedrock integration, persistence, notifications)
- **Data Layer**: DynamoDB for storing conversation history
- **AI Layer**: Amazon Bedrock Claude 3.5 Sonnet for generating responses
- **Monitoring**: CloudWatch (logs + alarms), SNS for alerts

## 📂 Project Structure
```
.
├── terraform/             # Infrastructure as Code
│   ├── main.tf            # AWS resources (API GW, Lambda, DynamoDB, SNS, etc.)
│   ├── variables.tf
│   ├── outputs.tf
│   └── cloudwatch.tf
├── lambda_function/       # Lambda source code
│   ├── main.py            # Lambda handler
│   └── requirements.txt
├── frontend/              # React.js web client
│   └── src/App.js
└── README.md
```

## ⚙️ Deployment Steps

### 1. Infrastructure (Terraform)
```bash
cd terraform
terraform init
terraform plan
terraform apply
```

### 2. Lambda Function
```bash
cd lambda_function
pip install -r requirements.txt -t .
zip -r ../lambda_function.zip .
cd ..
terraform apply
```

### 3. Frontend
```bash
cd frontend
npm install
npm start
```

👉 Update `API_URL` in `App.js` with your API Gateway endpoint.

## 🧪 Testing
Use Postman or curl to test API Gateway:
```bash
curl -X POST https://<api_id>.execute-api.<region>.amazonaws.com/dev \
  -H "Content-Type: application/json" \
  -d '{"user_id":"123", "message":"Hello bot"}'
```

- Open the React app (`npm start`) and chat with the bot.
- Check CloudWatch logs for Lambda execution details.
- Break the flow intentionally (e.g., invalid payload) to test SNS error alerts.

## 📈 Benefits
- **Scalable**, cost-efficient, and pay-per-use architecture
- **Secure**, managed entirely with Terraform IaC
- **AI-powered**, language-flexible (supports English/Turkish responses)
- **Easy to extend** with new features (multi-channel, CRM integration, etc.)

## 📌 Repository Info
- **Repo Name**: ai-customer-service-bot
- **Description**: AI-powered customer service bot built on AWS Bedrock, with Lambda, DynamoDB, API Gateway, SNS, CloudWatch, and a React.js frontend.

## 🙌 Contributing
Pull requests are welcome! For major changes, please open an issue first to discuss what you’d like to change.

## 📜 License
This project is licensed under the MIT License.

🔥 With this setup, you now have a production-ready AI customer service bot running fully on AWS. 