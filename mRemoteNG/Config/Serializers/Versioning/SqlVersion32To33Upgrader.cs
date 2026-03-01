using mRemoteNG.App;
using mRemoteNG.Config.DatabaseConnectors;
using mRemoteNG.Messages;
using System;
using System.Data.Common;
using System.Runtime.Versioning;

namespace mRemoteNG.Config.Serializers.Versioning
{
    [SupportedOSPlatform("windows")]
    public class SqlVersion32To33Upgrader(IDatabaseConnector databaseConnector) : IVersionUpgrader
    {
        private readonly Version _version = new(3, 3);
        private readonly IDatabaseConnector _databaseConnector = databaseConnector ?? throw new ArgumentNullException(nameof(databaseConnector));

        public bool CanUpgrade(Version currentVersion)
        {
            return currentVersion == new Version(3, 2) ||
                (currentVersion <= new Version(3, 3) &&
                currentVersion < _version);
        }

        public Version Upgrade()
        {
            Runtime.MessageCollector.AddMessage(MessageClass.InformationMsg,
                $"Upgrading database to version {_version}.");

            // Add missing external tool columns for auth/SSH credentials and visibility
            const string msSqlAlter = @"
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='tblExternalTools' AND COLUMN_NAME='Hidden')
    ALTER TABLE tblExternalTools ADD [Hidden] [bit] NOT NULL DEFAULT 0;
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='tblExternalTools' AND COLUMN_NAME='AuthType')
    ALTER TABLE tblExternalTools ADD [AuthType] [nvarchar](256) NOT NULL DEFAULT '';
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='tblExternalTools' AND COLUMN_NAME='AuthUsername')
    ALTER TABLE tblExternalTools ADD [AuthUsername] [nvarchar](512) NOT NULL DEFAULT '';
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='tblExternalTools' AND COLUMN_NAME='AuthPassword')
    ALTER TABLE tblExternalTools ADD [AuthPassword] [nvarchar](1024) NOT NULL DEFAULT '';
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='tblExternalTools' AND COLUMN_NAME='PrivateKeyFile')
    ALTER TABLE tblExternalTools ADD [PrivateKeyFile] [nvarchar](1024) NOT NULL DEFAULT '';
IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='tblExternalTools' AND COLUMN_NAME='Passphrase')
    ALTER TABLE tblExternalTools ADD [Passphrase] [nvarchar](1024) NOT NULL DEFAULT '';
";

            // MySQL: individual ALTERs (no IF NOT EXISTS for ADD COLUMN in MySQL 8.x)
            string[] mySqlAlters =
            [
                "ALTER TABLE `tblExternalTools` ADD COLUMN `Hidden` tinyint NOT NULL DEFAULT 0",
                "ALTER TABLE `tblExternalTools` ADD COLUMN `AuthType` varchar(256) NOT NULL DEFAULT ''",
                "ALTER TABLE `tblExternalTools` ADD COLUMN `AuthUsername` varchar(512) NOT NULL DEFAULT ''",
                "ALTER TABLE `tblExternalTools` ADD COLUMN `AuthPassword` varchar(1024) NOT NULL DEFAULT ''",
                "ALTER TABLE `tblExternalTools` ADD COLUMN `PrivateKeyFile` varchar(1024) NOT NULL DEFAULT ''",
                "ALTER TABLE `tblExternalTools` ADD COLUMN `Passphrase` varchar(1024) NOT NULL DEFAULT ''",
            ];

            const string mySqlUpdate = @"SET SQL_SAFE_UPDATES=0; UPDATE tblRoot SET ConfVersion=?; SET SQL_SAFE_UPDATES=1;";
            const string msSqlUpdate = @"UPDATE tblRoot SET ConfVersion=@confVersion;";

            using (DbTransaction sqlTran = _databaseConnector.DbConnection().BeginTransaction(System.Data.IsolationLevel.Serializable))
            {
                DbCommand dbCommand;
                if (_databaseConnector is MSSqlDatabaseConnector or OdbcDatabaseConnector)
                {
                    dbCommand = _databaseConnector.DbCommand(msSqlAlter);
                    dbCommand.Transaction = sqlTran;
                    dbCommand.ExecuteNonQuery();
                    dbCommand = _databaseConnector.DbCommand(msSqlUpdate);
                    dbCommand.Transaction = sqlTran;
                }
                else if (_databaseConnector is MySqlDatabaseConnector)
                {
                    // MySQL auto-commits DDL, so execute each ALTER separately.
                    // Ignore "duplicate column" errors for idempotency.
                    foreach (string alterSql in mySqlAlters)
                    {
                        try
                        {
                            dbCommand = _databaseConnector.DbCommand(alterSql);
                            dbCommand.Transaction = sqlTran;
                            dbCommand.ExecuteNonQuery();
                        }
                        catch (Exception ex) when (ex.Message.Contains("Duplicate column", StringComparison.OrdinalIgnoreCase))
                        {
                            // Column already exists — safe to ignore
                        }
                    }

                    dbCommand = _databaseConnector.DbCommand(mySqlUpdate);
                    dbCommand.Transaction = sqlTran;
                }
                else
                {
                    throw new NotSupportedException("Unknown database back-end");
                }

                DbParameter pConfVersion = dbCommand.CreateParameter();
                pConfVersion.ParameterName = "confVersion";
                pConfVersion.Value = _version.ToString();
                pConfVersion.DbType = System.Data.DbType.String;
                pConfVersion.Direction = System.Data.ParameterDirection.Input;
                dbCommand.Parameters.Add(pConfVersion);

                dbCommand.ExecuteNonQuery();
                sqlTran.Commit();
            }

            return _version;
        }
    }
}
