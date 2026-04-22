using System;
using System.Collections.Generic;
using System.Runtime.Versioning;
using mRemoteNG.Connection;
using mRemoteNG.Properties;
using NUnit.Framework;

namespace mRemoteNGTests.Connection
{
    [TestFixture, NonParallelizable, SupportedOSPlatform("windows")]
    public class ConnectionsFileResolverTests
    {
        private string _savedPath = string.Empty;
        private string _resolvedPath = string.Empty;

        [SetUp]
        public void Save()
        {
            _savedPath = OptionsConnectionsPage.Default.ConnectionFilePath;
            _resolvedPath = OptionsConnectionsPage.Default.ResolvedConnectionFilePath;
            OptionsConnectionsPage.Default.ConnectionFilePath = string.Empty;
            OptionsConnectionsPage.Default.ResolvedConnectionFilePath = string.Empty;
        }

        [TearDown]
        public void Restore()
        {
            OptionsConnectionsPage.Default.ConnectionFilePath = _savedPath;
            OptionsConnectionsPage.Default.ResolvedConnectionFilePath = _resolvedPath;
        }

        private static ConnectionsFileResolver.Candidate Cand(string path, DateTime mtimeUtc, long size = 100, string? label = null)
            => new(path, mtimeUtc, size, label ?? path);

        [Test]
        public void Resolve_NoCandidates_ReturnsNull_AndDoesNotPrompt()
        {
            bool called = false;
            ConnectionsFileResolver.Candidate? result = ConnectionsFileResolver.Resolve(
                Array.Empty<ConnectionsFileResolver.Candidate>(),
                (_, _) => { called = true; return (null, false); });

            Assert.That(result, Is.Null);
            Assert.That(called, Is.False);
        }

        [Test]
        public void Resolve_SingleCandidate_ReturnsIt_WithoutPrompting()
        {
            ConnectionsFileResolver.Candidate only = Cand(@"C:\a\confCons.xml", DateTime.UtcNow);
            bool called = false;

            ConnectionsFileResolver.Candidate? result = ConnectionsFileResolver.Resolve(
                new[] { only },
                (_, _) => { called = true; return (null, false); });

            Assert.That(result, Is.SameAs(only));
            Assert.That(called, Is.False);
        }

        [Test]
        public void Resolve_MultipleCandidates_PromptsWithNewestPreselected()
        {
            ConnectionsFileResolver.Candidate oldC = Cand(@"C:\old\confCons.xml", DateTime.UtcNow.AddDays(-30));
            ConnectionsFileResolver.Candidate newC = Cand(@"C:\new\confCons.xml", DateTime.UtcNow);
            ConnectionsFileResolver.Candidate? suggestedSeen = null;

            ConnectionsFileResolver.Candidate? result = ConnectionsFileResolver.Resolve(
                new[] { oldC, newC },
                (list, suggested) =>
                {
                    suggestedSeen = suggested;
                    return (suggested, false);
                });

            Assert.That(result, Is.SameAs(newC), "Newest should win when user keeps pre-selection.");
            Assert.That(suggestedSeen, Is.SameAs(newC), "Pre-selected candidate should be the newest by mtime.");
        }

        [Test]
        public void Resolve_UserCancels_ReturnsNull()
        {
            ConnectionsFileResolver.Candidate a = Cand(@"C:\a\confCons.xml", DateTime.UtcNow.AddDays(-1));
            ConnectionsFileResolver.Candidate b = Cand(@"C:\b\confCons.xml", DateTime.UtcNow);

            ConnectionsFileResolver.Candidate? result = ConnectionsFileResolver.Resolve(
                new[] { a, b },
                (_, _) => (null, false));

            Assert.That(result, Is.Null);
            Assert.That(OptionsConnectionsPage.Default.ResolvedConnectionFilePath, Is.Empty,
                "Nothing is persisted when the user cancels.");
        }

        [Test]
        public void Resolve_RememberChoice_PersistsToBothSettings()
        {
            ConnectionsFileResolver.Candidate a = Cand(@"C:\a\confCons.xml", DateTime.UtcNow.AddDays(-1));
            ConnectionsFileResolver.Candidate b = Cand(@"C:\b\confCons.xml", DateTime.UtcNow);

            ConnectionsFileResolver.Candidate? result = ConnectionsFileResolver.Resolve(
                new[] { a, b },
                (_, _) => (a, true));

            Assert.That(result, Is.SameAs(a));
            Assert.That(OptionsConnectionsPage.Default.ConnectionFilePath, Is.EqualTo(a.Path));
            Assert.That(OptionsConnectionsPage.Default.ResolvedConnectionFilePath, Is.EqualTo(a.Path));
        }

        [Test]
        public void Resolve_SessionOnlyChoice_UpdatesResolvedButNotSaved()
        {
            ConnectionsFileResolver.Candidate a = Cand(@"C:\a\confCons.xml", DateTime.UtcNow.AddDays(-1));
            ConnectionsFileResolver.Candidate b = Cand(@"C:\b\confCons.xml", DateTime.UtcNow);

            ConnectionsFileResolver.Candidate? result = ConnectionsFileResolver.Resolve(
                new[] { a, b },
                (_, _) => (b, false));

            Assert.That(result, Is.SameAs(b));
            Assert.That(OptionsConnectionsPage.Default.ConnectionFilePath, Is.Empty,
                "Session-only choice does not touch the persistent ConnectionFilePath.");
            Assert.That(OptionsConnectionsPage.Default.ResolvedConnectionFilePath, Is.EqualTo(b.Path),
                "Session-only choice updates the in-memory resolved path.");
        }

        [Test]
        public void Resolve_PriorSavedChoice_HonouredSilently()
        {
            ConnectionsFileResolver.Candidate a = Cand(@"C:\a\confCons.xml", DateTime.UtcNow.AddDays(-1));
            ConnectionsFileResolver.Candidate b = Cand(@"C:\b\confCons.xml", DateTime.UtcNow);

            OptionsConnectionsPage.Default.ResolvedConnectionFilePath = a.Path;
            bool called = false;

            ConnectionsFileResolver.Candidate? result = ConnectionsFileResolver.Resolve(
                new[] { a, b },
                (_, _) => { called = true; return (null, false); });

            Assert.That(result, Is.SameAs(a));
            Assert.That(called, Is.False, "Prior saved choice must not show the picker again.");
        }

        [Test]
        public void Resolve_PriorSavedChoice_NotInCandidates_FallsBackToPrompt()
        {
            ConnectionsFileResolver.Candidate a = Cand(@"C:\a\confCons.xml", DateTime.UtcNow.AddDays(-1));
            ConnectionsFileResolver.Candidate b = Cand(@"C:\b\confCons.xml", DateTime.UtcNow);

            OptionsConnectionsPage.Default.ResolvedConnectionFilePath = @"C:\nolongerexists\confCons.xml";
            bool called = false;

            ConnectionsFileResolver.Candidate? result = ConnectionsFileResolver.Resolve(
                new[] { a, b },
                (_, _) => { called = true; return (b, false); });

            Assert.That(result, Is.SameAs(b));
            Assert.That(called, Is.True, "When the saved path is gone, the picker must be shown.");
        }
    }
}
