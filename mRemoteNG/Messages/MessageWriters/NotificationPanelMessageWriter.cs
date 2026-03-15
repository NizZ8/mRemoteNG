using System;
using System.Collections.Generic;
using System.Runtime.Versioning;
using System.Windows.Forms;
using mRemoteNG.UI;
using mRemoteNG.UI.Window;

namespace mRemoteNG.Messages.MessageWriters
{
    [SupportedOSPlatform("windows")]
    public class NotificationPanelMessageWriter(ErrorAndInfoWindow messageWindow) : IMessageWriter
    {
        private readonly ErrorAndInfoWindow _messageWindow = messageWindow ?? throw new ArgumentNullException(nameof(messageWindow));
        private List<ListViewItem>? _pendingItems = [];

        public void Write(IMessage message)
        {
            NotificationMessageListViewItem lvItem = new(message);
            AddToList(lvItem);
        }

        private void AddToList(ListViewItem lvItem)
        {
            if (_messageWindow.lvErrorCollector.IsDisposed)
                return;

            // Buffer messages until the control handle is created.
            // ErrorAndInfoWindow starts in DockBottomAutoHide — its handle is only
            // created when the user first opens the panel, which is well after
            // startup timing messages are posted (#53).
            if (_pendingItems != null)
            {
                if (!_messageWindow.lvErrorCollector.IsHandleCreated)
                {
                    if (_pendingItems.Count == 0)
                        _messageWindow.lvErrorCollector.HandleCreated += OnHandleCreated;
                    _pendingItems.Add(lvItem);
                    return;
                }

                // Handle already exists — flush and switch to direct mode
                FlushPending();
            }

            if (_messageWindow.lvErrorCollector.InvokeRequired)
            {
                try
                {
                    _messageWindow.lvErrorCollector.Invoke((MethodInvoker)(() => AddToList(lvItem)));
                }
                catch (System.ComponentModel.InvalidAsynchronousStateException)
                {
                    return;
                }
                catch (ObjectDisposedException)
                {
                    return;
                }
                catch (InvalidOperationException)
                {
                    return;
                }
            }
            else
            {
                _messageWindow.AddMessage(lvItem);
            }
        }

        private void OnHandleCreated(object? sender, EventArgs e)
        {
            _messageWindow.lvErrorCollector.HandleCreated -= OnHandleCreated;
            FlushPending();
        }

        private void FlushPending()
        {
            if (_pendingItems == null) return;
            var items = _pendingItems;
            _pendingItems = null; // switch to direct mode permanently
            foreach (var pending in items)
                _messageWindow.AddMessage(pending);
        }
    }
}
