namespace RatioForge.Tests
{
    using System;

    using NUnit.Framework;

    [TestFixture]
    public class TrackerUrlBuilderTests
    {
        private const string Hash = "00112233445566778899aabbccddeeff10203040";

        [Test]
        public void AnnounceShouldApplyClientTemplateAndNormalizeCounters()
        {
            TorrentClient client = TorrentClientFactory.GetClient("qBittorrent 5.1.2");
            var torrent = CreateTorrentInfo("https://tracker.example/announce?passkey=abc");

            string result = TrackerUrlBuilder.BuildAnnounce(torrent, client, "&event=started", "192.0.2.10");

            Assert.Multiple((Action)(() =>
            {
                Assert.That(result, Does.StartWith("https://tracker.example/announce?passkey=abc&"));
                Assert.That(result, Does.Contain("info_hash=%00%11%223DUfw%88%99%aa%bb%cc%dd%ee%ff%10%200%40"));
                Assert.That(result, Does.Contain("uploaded=16384"));
                Assert.That(result, Does.Contain("downloaded=32"));
                Assert.That(result, Does.Contain("left=968"));
                Assert.That(result, Does.Contain("numwant=200"));
                Assert.That(result, Does.Contain("event=started"));
            }));
        }

        [Test]
        public void ScrapeShouldReplaceLastAnnounceSegmentAndPreservePasskey()
        {
            TorrentClient client = TorrentClientFactory.GetClient("qBittorrent 5.1.2");
            var torrent = CreateTorrentInfo("https://tracker.example/announce/secret/announce?token=abc");

            string result = TrackerUrlBuilder.BuildScrape(torrent, client);

            Assert.That(
                result,
                Is.EqualTo("https://tracker.example/announce/secret/scrape?token=abc&info_hash=%00%11%223DUfw%88%99%aa%bb%cc%dd%ee%ff%10%200%40"));
        }

        [Test]
        public void ScrapeShouldReturnEmptyWhenTrackerHasNoAnnounceSegment()
        {
            TorrentClient client = TorrentClientFactory.GetClient("qBittorrent 5.1.2");
            var torrent = CreateTorrentInfo("https://tracker.example/tracker");

            Assert.That(TrackerUrlBuilder.BuildScrape(torrent, client), Is.Empty);
        }

        private static TorrentInfo CreateTorrentInfo(string tracker)
        {
            return new TorrentInfo(16385, 47)
            {
                tracker = tracker,
                hash = Hash,
                left = 953,
                totalsize = 1000,
                peerID = "-qB5120-123456789012",
                port = "6881",
                key = "123",
                numberOfPeers = "0",
            };
        }
    }
}
