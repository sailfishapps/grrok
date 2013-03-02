//Copyright Jon Levell, 2012
//
//This file is part of Grrok.
//
//Grrok is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the
//Free Software Foundation, either version 2 of the License, or (at your option) any later version.
//Grrok is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of
//MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
//You should have received a copy of the GNU General Public License along with Grrok (on a Maemo/Meego system there is a copy
//in /usr/share/common-licenses. If not, see http://www.gnu.org/licenses/.

import QtQuick 1.1
import Sailfish.Silica 1.0

Page {
    id: feedsPage
   // tools: feedsTools
    property string categoryId: ""
    property int numStatusUpdates
    property bool loading: false
    property string pageTitle: ""

    ListModel {
        id: feedsModel
    }

    SilicaListView {
        id: listView
        anchors.fill: parent
        model: feedsModel
        header:  PageHeader {
            title: pageTitle
        }

        PullDownMenu {
            MenuItem {
                id: toggleUnread
                text: qsTr("Toggle Unread Only")
                onClicked: {
                    var gr = rootWindow.getGoogleReader();
                    var oldval = gr.getShowAll();
                    var newval = !oldval;
                    gr.setShowAll(newval);

                    //console.log("Updating categories with showAll: "+newval+"\n");
                    updateFeeds();
                }
            }
            MenuItem {
                text: qsTr("Jump to next")
                onClicked: if(!loading) jumpToChosenFeed()
            }
        }

        delegate:  Item {
            id: listItem
            height: theme.itemSizeMedium
            width: parent.width

            BackgroundItem {
                id: background
                anchors.fill: parent
                onClicked: showFeed(model.feedId);
            }

            Row {
                anchors {
                    fill: parent
                    rightMargin: theme.paddingMedium
                    leftMargin: theme.paddingMedium
                }
                Column {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - drilldown.width

                    Label {
                        id: mainText
                        text: model.title
                        font.pixelSize: theme.fontSizeMedium
                        color: (model.unreadcount > 0) ? theme.primaryColor: theme.secondaryColor;
                        truncationMode: TruncationMode.Fade
                        width: parent.width
                    }

                    Label {
                        id: subText
                        text: model.subtitle
                        font.pixelSize: theme.fontSizeSmall
                        color: (model.unreadcount > 0) ? theme.highlightColor : theme.secondaryHighlightColor
                        truncationMode: TruncationMode.Fade
                        visible: text != ""
                        width: parent.width
                    }
                }
            }

            Image {
                id: drilldown
                source: "image://theme/icon-m-common-drilldown-arrow"
                anchors.right: parent.right;
                anchors.verticalCenter: parent.verticalCenter
                visible: (model.feedId != null)
            }
        }
    }

    Timer {
            id: delayedClose
            interval: 500; running: false; repeat: false
            onTriggered:  {
                pageStack.pop();
            }
        }

    function updateFeeds() {
        feedsModel.clear();
        var gr = rootWindow.getGoogleReader();
        var feeds = gr.getFeedsForCategory(categoryId);
        var showAll = gr.getShowAll();

        if(feeds.label) {
            pageTitle = feeds.label;
        } else {
            pageTitle = qsTr("All Feeds");
        }

        if(feeds && categoryId) {
            var emptyList = true;
            var i;
            var unreadcount;
            console.log("showing feeds for category: "+categoryId+"\n");
//            console.log(gr.dump(feeds.subscriptions[0]));

            //First add feed with unread items
            for(i=0; i < feeds.subscriptions.length; i++) {
                unreadcount = feeds.subscriptions[i].unreadcount;

                if( unreadcount && (unreadcount > 0)) {
                    emptyList = false;

                    feedsModel.append({
                                     title:     gr.html_entity_decode(feeds.subscriptions[i].title,'ENT_QUOTES'),
                                     subtitle:  "Unread: " + unreadcount,
                                     unreadcount:  unreadcount,
                                     feedId:     feeds.subscriptions[i].id,
                                     });
                }
            }
            //If we're showing all feeds, add the ones with no unread items
            if(showAll) {
                for(i=0; i < feeds.subscriptions.length; i++) {

                    unreadcount = feeds.subscriptions[i].unreadcount;
                    if(!unreadcount) {
                        unreadcount = 0;
                    }

                    if(unreadcount === 0) {
                        emptyList = false;

                        feedsModel.append({
                                         title:     gr.html_entity_decode(feeds.subscriptions[i].title,'ENT_QUOTES'),
                                         subtitle:  "Unread: " + unreadcount,
                                         unreadcount:  unreadcount,
                                         feedId:     feeds.subscriptions[i].id,
                                         });
                    }
                }
            }

            if(emptyList) {
                //Have we been told to close if we're empty?
                if(gr.getCloseIfEmpty()) {
                    //QML seems to get upset if we try and close here (page animation not yet completed?)
                    //So we'll close in a bit...
                    delayedClose.running = true;
                }
                if(showAll ||(feeds.subscriptions.length == 0) ) {
                    feedsModel.append({
                                          title: qsTr("No feeds in category"),
                                             subtitle: "",
                                             feedId: null,
                                             unreadCount: 0,
                                         });
                } else {
                    feedsModel.append({
                                             title: qsTr("Category has no unread items"),
                                             subtitle: "",
                                             feedId: null,
                                             unreadCount: 0,
                                         });
                }
            } else {
                //All necessary closeIfEmpty's have occurred
                gr.setCloseIfEmpty(false);
            }
        }
    }

    onCategoryIdChanged: {
        updateFeeds();
    }

    Component.onCompleted: {
        var gr = rootWindow.getGoogleReader();
        numStatusUpdates = gr.getNumStatusUpdates();
    }

    onStatusChanged: {
        var gr;

        if(status === PageStatus.Deactivating) {
            gr = rootWindow.getGoogleReader();
            numStatusUpdates = gr.getNumStatusUpdates();
        } else if (status === PageStatus.Activating) {
            gr = rootWindow.getGoogleReader();
            if(gr.getNumStatusUpdates() > numStatusUpdates) {
                numStatusUpdates = gr.getNumStatusUpdates();
                updateFeeds();
            }
        }
    }

    function showFeed(feedId) {
        if(feedId != null) {
            console.log("Loading items for "+feedId+"\n");
            var component = Qt.createComponent("ItemList.qml");
            if (component.status == Component.Ready) {
                pageStack.push(component, {feedId: feedId});
            } else {
                console.log("Error loading component:", component.errorString());
            }
        }
    }

    function jumpToChosenFeed() {
        var gr = rootWindow.getGoogleReader();

        var feedId = gr.pickFeed(categoryId);

        if(feedId) {
            showFeed(feedId);
        } else {
            //Close feeds window
            pageStack.pop();
        }
    }
}
