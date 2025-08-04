const AWS = require("aws-sdk");
const s3 = new AWS.S3();

exports.handler = async (event) => {
  const bucketName = process.env.AUDIT_BUCKET_NAME;
  const timestamp = new Date().toISOString();
  const key = `logs/${timestamp}.json`;

  const params = {
    Bucket: bucketName,
    Key: key,
    Body: JSON.stringify(event),
    ContentType: "application/json"
  };

  try {
    await s3.putObject(params).promise();
    console.log(`Successfully logged event to S3: ${key}`);
    return {
      statusCode: 200,
      body: JSON.stringify({ message: "Event logged" })
    };
  } catch (err) {
    console.error("Error writing to S3:", err);
    return {
      statusCode: 500,
      body: JSON.stringify({ message: "Error writing to S3", error: err.message })
    };
  }
};
