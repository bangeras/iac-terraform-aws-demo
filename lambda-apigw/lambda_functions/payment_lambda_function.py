def lambda_handler(event, context):
    print("Hello, Payment Lambda!")
    return {
        'statusCode': 200,
        'body': 'Hello from Payment Lambda function!'
    }