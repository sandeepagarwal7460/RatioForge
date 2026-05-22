namespace RatioForge
{
    using System;
    using System.IO;
    using System.Net;
    using System.Reflection;

    public class VersionChecker
    {
        private readonly Func<string> getServerVersion;
        public static readonly string LocalVersion = GetAssemblyVersion();
        public static readonly string PublicVersion = LocalVersion;
        public const string ReleaseDate = "22-05-2026";
        private const string ProgramPageVersion = "https://raw.githubusercontent.com/tsautier/RatioForge/master/version.txt";

        private readonly string userAgent;

        public VersionChecker(string log)
            : this(log, null)
        {
        }

        internal VersionChecker(string log, Func<string> getServerVersion)
        {
            this.userAgent = "RatioForge"
                             + $"/{LocalVersion} ({Environment.OSVersion}; .NET CLR {Environment.Version}; {Environment.UserName}.{Environment.ProcessorCount})";
            this.getServerVersion = getServerVersion ?? this.GetServerVersionId;
            this.Log = log;
        }

        // TODO: Replace with StringBuilder
        public string Log { get; private set; }

        internal string RemoteVersion { get; private set; }

        public bool CheckNewVersion()
        {
            try
            {
                bool result = false;
                this.Log = this.Log + ("Local Version: " + LocalVersion + "\n");
                this.Log = this.Log + ("Checking for new version..." + "\n");
                this.RemoteVersion = this.getServerVersion();
                //// mainForm.txtRemote.Text = remoteVersion;
                Version remoteVersion;
                Version localVersion;
                if (!Version.TryParse(this.RemoteVersion, out remoteVersion) || !Version.TryParse(LocalVersion, out localVersion))
                {
                    this.RemoteVersion = "error";
                    this.Log = this.Log + ("Error checking new version!!!" + "\n" + "\n");
                    return false;
                }

                this.Log = this.Log + ("Remote Version: " + this.RemoteVersion + "\n" + "\n");
                if (remoteVersion > localVersion)
                {
                    result = true;
                }

                return result;
            }
            catch (Exception exception1)
            {
                this.Log = this.Log + ("Error checking for new version:\n" + exception1.Message + "\n");
                return false;
            }
        }

        public string GetServerVersionId()
        {
            var url = ProgramPageVersion; // + LocalVersion;
            try
            {
                var request1 = (HttpWebRequest)WebRequest.Create(url);
                request1.UserAgent = this.userAgent;
                request1.Timeout = 2500;
                using (var response1 = (HttpWebResponse)request1.GetResponse())
                {
                    using (var reader1 = new StreamReader(response1.GetResponseStream()))
                    {
                        var data = reader1.ReadToEnd();
                        return data.Trim();
                    }
                }
            }
            catch (Exception exception1)
            {
                this.Log = this.Log + "Error in GetVersion(string url):\n" + exception1.Message + "\n";
            }

            return string.Empty;
        }

        private static string GetAssemblyVersion()
        {
            var attribute = typeof(VersionChecker).Assembly.GetCustomAttribute<AssemblyInformationalVersionAttribute>();
            var version = attribute?.InformationalVersion ?? typeof(VersionChecker).Assembly.GetName().Version?.ToString(3) ?? "0.0.0";
            var metadataIndex = version.IndexOf('+');
            return metadataIndex >= 0 ? version.Substring(0, metadataIndex) : version;
        }
    }
}
