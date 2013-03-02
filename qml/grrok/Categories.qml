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
    id: categoriesPage

    property int numStatusUpdates
    property bool loading: false

    ListModel {
        id: categoriesModel
    }

    SilicaListView {
        id: listView
        anchors.fill: parent

        model: categoriesModel

        header:
            PageHeader {
                title: "Categories"
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
                    updateCategories();
                }
            }

            MenuItem {
                id: about
                text: qsTr("About Grrok")
                onClicked: {
                    var component = Qt.createComponent("About.qml");
                    if (component.status == Component.Ready) {
                        pageStack.push(component);
                    } else {
                        console.log("Error loading component:", component.errorString());
                    }
                }
            }

            MenuItem {
                text: "Jump to next"
                onClicked: if(!loading){ jumpToChosenCategory(); }
            }

        }

        delegate:  Item {
            id: listItem
            height: theme.itemSizeMedium
            anchors.right: parent.right
            anchors.left: parent.left

            BackgroundItem {
                id: background
                anchors.fill: parent
                onClicked: showCategory(model.categoryId);
            }

            Row {
                anchors.fill: parent
                anchors.rightMargin: theme.paddingMedium
                anchors.leftMargin: theme.paddingMedium

                Column {
                    anchors.verticalCenter: parent.verticalCenter

                    Label {
                        id: mainText
                        text: model.title

                        font.pixelSize: theme.fontSizeMedium
                        color: (model.unreadcount > 0) ? theme.primaryColor : theme.secondaryColor;

                    }

                    Label {
                        id: subText
                        text: model.subtitle
                        font.pixelSize: theme.fontSizeSmall
                        color: (model.unreadcount > 0) ? theme.highlightColor : theme.secondaryHighlightColor

                        visible: text != ""
                    }
                }
            }

            Image {
                source: "image://theme/icon-m-common-drilldown-arrow"
                anchors.right: parent.right;
                anchors.verticalCenter: parent.verticalCenter
                visible: ((model.categoryId != null)? true: false)
            }

        }
    }

    function updateCategories() {
        var gr = rootWindow.getGoogleReader();
        var categories = gr.getCategories();
        var showAll = gr.getShowAll();
        categoriesModel.clear();

        if(categories) {
            var someCategories = false;
            var totalUnreadCount = 0;

            //first add all the categories with unread itens
            for(var category in categories) {
                someCategories = true;

                if(categories[category].unreadcount > 0) {
                    totalUnreadCount += categories[category].unreadcount;

                    categoriesModel.append({
                                               title:        gr.html_entity_decode(categories[category].label,'ENT_QUOTES'),
                                               subtitle:    "Unread: " + categories[category].unreadcount,
                                               unreadcount:  categories[category].unreadcount,
                                               categoryId:   category
                                           });
                }
            }

            //then if we are showing all categories, add the ones with no unread items
            if(showAll) {
                for(var cat in categories) {
                    if(categories[cat].unreadcount === 0) {
                        categoriesModel.append({
                                                   title:       gr.html_entity_decode(categories[cat].label,'ENT_QUOTES'),
                                                   subtitle:    "Unread: 0",
                                                   unreadcount:  0,
                                                   categoryId:   cat
                                               });
                    }
                }
            }

            if(   (totalUnreadCount > 0)
               || ((showAll) && someCategories)) {
                //Add the "All category"
                categoriesModel.insert(0, {
                                           title: qsTr("All Categories"),
                                           subtitle: "Unread: " + totalUnreadCount,
                                           categoryId: gr.constants['ALL_CATEGORIES'],
                                           unreadcount: totalUnreadCount,
                                       });
            } else if (someCategories) {
                //There are categories they just don't have unread items
                categoriesModel.append({
                                           title: qsTr("No categories have unread items"),
                                           subtitle: "",
                                           categoryId: null,
                                           unreadcount: 0,
                                       });
            } else {
                //There are no categories
                categoriesModel.append({
                                           title: qsTr("No categories to display"),
                                           subtitle: "",
                                           categoryId: null,
                                           unreadcount: 0,
                                       });
            }

            rootWindow.unreadCount = totalUnreadCount
        }
    }

    Component.onCompleted: {
        var gr = rootWindow.getGoogleReader();
        //gr.addStatusListener(categoriesStatusListener);
        numStatusUpdates = gr.getNumStatusUpdates();
        updateCategories();
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
                updateCategories();
            }
        }
    }

    function showCategory(categoryId) {
        if(categoryId != null) {
            console.log("Loading feeds for "+categoryId+"\n");
            var component = Qt.createComponent("Feeds.qml");
            if (component.status == Component.Ready) {
                pageStack.push(component, {categoryId: categoryId});
            } else {
                console.log("Error loading component:", component.errorString());
            }
        }
    }

    function jumpToChosenCategory() {
        var gr = rootWindow.getGoogleReader();
        showCategory(gr.pickCategory());
    }
}
