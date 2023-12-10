package main

import (
	"context"
	"fmt"
	"log"
	"os"

	"github.com/aws/aws-lambda-go/events"
	"github.com/aws/aws-lambda-go/lambda"
	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/service/sns"
)

type Client interface {
	Publish(ctx context.Context, params *sns.PublishInput, optFns ...func(*sns.Options)) (*sns.PublishOutput, error)
}

var client Client

func init() {
	cfg, err := config.LoadDefaultConfig(context.TODO())

	if err != nil {
		log.Fatalf("Fail to Load AWS SDK: %v\n", err)
	}

	client = sns.NewFromConfig(cfg)
}

func Handler(ctc context.Context, evt events.DynamoDBEvent) error {

	for _, record := range evt.Records {
		var message string

		newImage := record.Change.NewImage
		if record.EventName == "INSERT" {
			custId := newImage["custID"].Number()
			item := newImage["item"].String()
			quantity := newImage["quantity"].Number()
			price := newImage["price"].Number()
			total := newImage["total"].Number()

			message = fmt.Sprintf("New Order from Customer Id %s => %s %s (@US$ %s) with Total US$ %s", custId, quantity, item, price, total)
		} else if record.EventName == "MODIFY" {
			orderId := newImage["orderID"].String()

			message = fmt.Sprintf("Customer Finish Payment for Order %s", orderId)
		}

		publishInput := &sns.PublishInput{
			Message:  &message,
			TopicArn: aws.String(os.Getenv("topic_arn")),
		}

		out, err := client.Publish(context.Background(), publishInput)
		if err != nil {
			return err
		}

		fmt.Println(out.MessageId)
	}
	return nil
}

func main() {
	lambda.Start(Handler)
}
