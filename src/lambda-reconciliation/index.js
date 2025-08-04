const AWS = require("aws-sdk");
const { Client } = require("pg");

const ssm = new AWS.SSM();

const getParameter = async (name, decrypt = false) => {
  const param = await ssm.getParameter({ Name: name, WithDecryption: decrypt }).promise();
  return param.Parameter.Value;
};

exports.handler = async () => {
  try {
    const [host, user, password, dbName] = await Promise.all([
      getParameter("/billing/db_host"),
      getParameter("/billing/db_user"),
      getParameter("/billing/db_password", true),
      getParameter("/billing/db_name")
    ]);

    const client = new Client({
      host,
      user,
      password,
      database: dbName,
      port: 5432,
      ssl: false // change to { rejectUnauthorized: false } if connecting to RDS
    });

    await client.connect();

    const result = await client.query("SELECT * FROM payments WHERE status = 'PENDING'");
    console.log("Pending payments:", result.rows);

    await client.end();
    return {
      statusCode: 200,
      body: JSON.stringify({ message: "Reconciliation complete", count: result.rowCount })
    };

  } catch (error) {
    console.error("Reconciliation error:", error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: error.message })
    };
  }
};
