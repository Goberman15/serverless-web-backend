package main

import (
	"context"
	"encoding/json"
	"fmt"
	"log"
	"os"
	"strings"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb"
	"github.com/aws/aws-sdk-go-v2/service/dynamodb/types"
	"github.com/google/uuid"
)

type Client interface {
	PutItem(ctx context.Context, params *dynamodb.PutItemInput, optFns ...func(*dynamodb.Options)) (*dynamodb.PutItemOutput, error)
}

type Order struct {
	CustomerId int    `json:"id"`
	Item       string `json:"item"`
	Price      int    `json:"price"`
	Quantity   int    `json:"quantity"`
}

var client Client

func init() {
	cfg, err := config.LoadDefaultConfig(context.TODO())

	if err != nil {
		log.Fatalf("Fail to Load AWS SDK: %v\n", err)
	}

	client = dynamodb.NewFromConfig(cfg)

}

func Handler(ctx context.Context, evt events.SQSEvent) error {
	var order Order
	for _, message := range evt.Records {
		fmt.Printf("Receive Message from %s on %s\n", message.EventSource, message.AWSRegion)
		fmt.Printf("%q\n", message.Body)

		s := strings.NewReader(message.Body)

		fmt.Println("Decoding JSON...")
		err := json.NewDecoder(s).Decode(&order)
		if err != nil {
			return err
		}

		putItemInput := &dynamodb.PutItemInput{
			TableName: aws.String(os.Getenv("table_name")),
			Item: map[string]types.AttributeValue{
				"orderID": &types.AttributeValueMemberS{
					Value: uuid.NewString(),
				},
				"custID": &types.AttributeValueMemberN{
					Value: fmt.Sprint(order.CustomerId),
				},
				"price": &types.AttributeValueMemberN{
					Value: fmt.Sprint(order.Price),
				},
				"quantity": &types.AttributeValueMemberN{
					Value: fmt.Sprint(order.Quantity),
				},
				"total": &types.AttributeValueMemberN{
					Value: fmt.Sprint(order.Price * order.Quantity),
				},
			},
		}

		fmt.Println("Put Item into DynamoDB Table")
		out, err := client.PutItem(context.Background(), putItemInput)

		if err != nil {
			return err
		}

		fmt.Printf("%+v\n", out.Attributes)
	}

	return nil
}

func main() {
	lambda.Start(Handler)
}
