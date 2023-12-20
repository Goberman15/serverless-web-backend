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
	UpdateItem(ctx context.Context, params *dynamodb.UpdateItemInput, optFns ...func(*dynamodb.Options)) (*dynamodb.UpdateItemOutput, error)
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

		action := *message.MessageAttributes["action"].StringValue

		if action == "PlaceOrder" {
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
					"item": &types.AttributeValueMemberS{
						Value: order.Item,
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
					"isPaid": &types.AttributeValueMemberBOOL{
						Value: false,
					},
				},
			}

			fmt.Println("Put Item into DynamoDB Table")
			out, err := client.PutItem(context.Background(), putItemInput)

			if err != nil {
				return err
			}

			fmt.Println("Success Add Order to DynamoDB")
			fmt.Printf("%+v\n", out.Attributes)
		} else if action == "PayOrder" {
			fmt.Println("Process Payment for", message.Body)

			updateItemInput := &dynamodb.UpdateItemInput{
				TableName: aws.String(os.Getenv("table_name")),
				Key: map[string]types.AttributeValue{
					"orderID": &types.AttributeValueMemberS{
						Value: message.Body,
					},
				},
				UpdateExpression: aws.String("set isPaid = :paidStatusNew"),
				ConditionExpression: aws.String("isPaid = :paidStatusOld"),
				ExpressionAttributeValues: map[string]types.AttributeValue{
					":paidStatusNew": &types.AttributeValueMemberBOOL{
						Value: true,
					},
					":paidStatusOld": &types.AttributeValueMemberBOOL{
						Value: false,
					},
				},
				ReturnValues: "ALL_NEW",
			}

			fmt.Println("Updating Data on DynamoDB")
			out, err := client.UpdateItem(context.Background(), updateItemInput)
			if err != nil {
				return err
			}

			fmt.Println("Success Update Order's Payment Status in DynamoDB")
			fmt.Printf("%+v\n", out.Attributes)
		} else {
			return fmt.Errorf("invalid action type")
		}
	}

	return nil
}

func main() {
	lambda.Start(Handler)
}
