import json
import boto3
import os
from datetime import datetime
from boto3.dynamodb.conditions import Key

dynamodb = boto3.resource("dynamodb")
table = dynamodb.Table("conversation_history")
sns = boto3.client("sns")

# Bedrock client
bedrock = boto3.client("bedrock-runtime", region_name=os.environ.get("AWS_REGION", "us-east-1"))

def lambda_handler(event, context):
    try:
        # 1. API Gateway'den gelen body'yi oku
        body = json.loads(event.get("body", "{}"))
        user_id = body.get("user_id", "anonymous")
        message = body.get("message", "")

        # 2. Kullanıcının konuşma geçmişini al
        response = table.query(
            KeyConditionExpression=Key("user_id").eq(user_id)
        )
        history = response.get("Items", [])

        # 3. Prompt hazırla
        conversation_context = "\n".join(
            [f"User: {h['message']} \nBot: {h['response']}" for h in history]
        )
        prompt = f"""
        Sen bir müşteri hizmetleri botusun. Yanıtlarını her zaman **Türkçe** ver. 
        Kullanıcının sorusuna net, kısa ve marka diline uygun cevap ver. Gereksiz tekrar yapma.

        Kullanıcının sorusu: {message}

        Önceki konuşmalar:
        {conversation_context}

        Yanıtın:
        """

        # 4. Claude 3.5 modelini çağır
        payload = {
            "anthropic_version": "bedrock-2023-05-31",
            "max_tokens": 512,
            "messages": [
                {
                    "role": "user",
                    "content": f"""
        Sen bir müşteri hizmetleri asistanısın. 
        Cevaplarını daima **Ingilizce** ver. 
        Yanıtlarını kısa, net ve kargo/destek konularına odaklı yaz.
        Gereksiz tekrar yapma. 

        Kullanıcının sorusu: {message}
        """
                }
            ]
        }

        bedrock_response = bedrock.invoke_model(
            modelId="anthropic.claude-3-5-sonnet-20240620-v1:0",
            body=json.dumps(payload),
            contentType="application/json",
            accept="application/json"
        )

        response_body = json.loads(bedrock_response['body'].read())
        answer = response_body["content"][0]["text"]

        # 5. DynamoDB'ye kaydet
        table.put_item(
            Item={
                "user_id": user_id,
                "timestamp": datetime.utcnow().isoformat(),
                "message": message,
                "response": answer
            }
        )

        # 6. Yanıtı döndür (✅ CORS headerları burada!)
        return {
            "statusCode": 200,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Headers": "Content-Type",
                "Access-Control-Allow-Methods": "OPTIONS,POST"
            },
            "body": json.dumps({"answer": answer})
        }



    except Exception as e:
        # Hata SNS ile bildirilsin
        sns.publish(
            TopicArn=os.environ["SNS_TOPIC_ARN"],
            Message=f"Lambda hatası: {str(e)}"
        )
        return {
            "statusCode": 500,
            "headers": {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Headers": "Content-Type",
                "Access-Control-Allow-Methods": "OPTIONS,POST"
            },
            "body": json.dumps({"error": str(e)})
        }
