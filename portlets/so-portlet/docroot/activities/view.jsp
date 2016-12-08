<%--
/**
 * Copyright (c) 2000-present Liferay, Inc. All rights reserved.
 *
 * This file is part of Liferay Social Office. Liferay Social Office is free
 * software: you can redistribute it and/or modify it under the terms of the GNU
 * Affero General Public License as published by the Free Software Foundation,
 * either version 3 of the License, or (at your option) any later version.
 *
 * Liferay Social Office is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
 * FITNESS FOR A PARTICULAR PURPOSE. See the GNU Affero General Public License
 * for more details.
 *
 * You should have received a copy of the GNU General Public License along with
 * Liferay Social Office. If not, see http://www.gnu.org/licenses/agpl-3.0.html.
 */
--%>

<%@ include file="/activities/init.jsp" %>

<%
	Group group = themeDisplay.getScopeGroup();

	PortletURL portletURL = renderResponse.createRenderURL();

	long single = ParamUtil.getLong(request, "showSingle");

	portletURL.setParameter("tabs1", tabs1);
%>

<link href="<%=request.getContextPath()%>/activities/js/alloy-editor/assets/alloy-editor-ocean-min.css" rel="stylesheet">
<script src="<%=request.getContextPath()%>/activities/js/alloy-editor/alloy-editor-all.js"></script>
<script src="<%=request.getContextPath()%>/activities/js/tribute.js"></script>

<div class="likes-modal" id="aui_popup_content" ></div>

<c:if test="<%= group.isUser() && layout.isPrivateLayout() %>">
	<div class="header-fixer hioa-accordion-header">
		<h2><liferay-ui:message key="activities-title"/></h2>
	</div>
	<div class="hioa-accordion-content">
	<liferay-ui:tabs
			names="my-sites,me"
			url="<%= portletURL.toString() %>"
			value="<%= tabs1 %>"
	/>
</c:if>
<div class="social-activities"></div>

<div class="loading-bar"></div>

<c:if test="<%= group.isUser() && layout.isPrivateLayout() %>">
	</div>
</c:if>

	<aui:script use="aui-base,aui-io-request-deprecated,aui-parse-content,liferay-so-scroll">
	var activities = A.one('#p_p_id<portlet:namespace />');
	var body = A.getBody();

	var loadingBar = activities.one('.loading-bar');
	var socialActivities = activities.one('.social-activities');

	socialActivities.plug(A.Plugin.ParseContent);

	var win = A.getWin();

	win.plug(
			Liferay.SO.Scroll,
			{
				edgeProximity: 0.4
			}
	);

	var loading = false;

	<portlet:namespace />start = 0;

	var loadNewContent = function() {
		loadingBar.removeClass('loaded');

		loading = true;

		setTimeout(
				function() {
					<portlet:renderURL var="viewActivitySetsURL" windowState="<%= LiferayWindowState.EXCLUSIVE.toString() %>">
					<c:choose>
					<c:when test="<%= GetterUtil.getBoolean(PropsUtil.get(PropsKeys.SOCIAL_ACTIVITY_SETS_ENABLED)) %>">
					<portlet:param name="mvcPath" value="/activities/view_activity_sets.jsp" />
					</c:when>
					<c:otherwise>
					<portlet:param name="mvcPath" value="/activities/view_activities.jsp" />
					</c:otherwise>
					</c:choose>
					<%if (single > 0) { %>
					<portlet:param name="showSingle" value="<%= String.valueOf(single) %>" />
					<% } %>
					<portlet:param name="tabs1" value="<%= tabs1 %>" />
					</portlet:renderURL>

					var uri = '<%= viewActivitySetsURL %>';

					uri = Liferay.Util.addParams('<portlet:namespace />start=' + <portlet:namespace />start, uri) || uri;

					A.io.request(
							uri,
							{
								after: {
									success: function(event, id, obj) {
										var responseData = this.get('responseData');

										socialActivities.append(responseData);

										loadingBar.addClass('loaded');

										loading = false;

										if (!activities.one('.no-activities')) {
											/*if (body.height() < win.height()) {
											 loadNewContent();
											 }
											 else if (win.width() < 768) {*/
											loading = true;

											var manualLoaderTemplate =
													'<div class="manual-loader">' +
													'<button href="javascript:;"><liferay-ui:message key="load-more-activities" /></button>' +
													'</div>';
											<%if (single < 1) { %>
											socialActivities.append(manualLoaderTemplate);
											<% } %>
											/*}*/
										}
									}
								}
							}
					);
				},
				1000
		);
	}

	if (socialActivities && !loading) {
		loadNewContent();
	}

	var updateCommentCardsEdit = function (editor, mbMessageIdOrMicroblogsEntryId) {
		var data = editor.getData();
		Liferay.Service(
				'/socialactivitymessage-portlet.hioasocialactivity/add-direct-cards',
				{
					body: data,
					ignore: JSON.stringify(Liferay['<portlet:namespace />-wysiwyg-skip'+mbMessageIdOrMicroblogsEntryId])
				},
				function(obj) {
					A.one('#<portlet:namespace />cards'+mbMessageIdOrMicroblogsEntryId).setHTML(obj+'<div class="clearfix"></div>');
					A.one('#<portlet:namespace />cards'+mbMessageIdOrMicroblogsEntryId).all('.remove-all').each(function (node) {
						node.on('click', function (event) {
							var card = event.currentTarget.ancestor('.card-rich');
							var url = card.one('.url a');
							Liferay['<portlet:namespace />-wysiwyg-skip'+mbMessageIdOrMicroblogsEntryId].push(url.getAttribute('href'));
							card.remove(true);
							card.destroy();
							updateCommentCardsEdit(editor, true);
						});
					});
				}
		);
	};

	win.scroll.on(
			'bottom-edge',
			function(event) {
				if (activities.one('.no-activities')) {
					loading = true;
				}

				if (!loading) {
					loadNewContent();
				}
			}
	);

	socialActivities.delegate(
			'click',
			function(event) {
				var manualLoader = socialActivities.one('.manual-loader');
				if (typeof _sz !== 'undefined' && _sz != null) {
					_sz.push(['event', 'stream', 'Load more']);
				}

				manualLoader.remove(true);

				loadNewContent();
			},
			'.manual-loader button'
	)

	socialActivities.delegate(
			'click',
			function(event) {
				var currentTarget = event.currentTarget;

				var activityFooterToolbar = currentTarget.ancestor('.activity-footer-toolbar');

				var commentsContainer = activityFooterToolbar.siblings('.comments-container');

				var commentsList = commentsContainer.one('.comments-list');

				if (commentsList.attr('loaded')) {
					commentsList.toggle();
				}
				else {
					var uri = '<liferay-portlet:resourceURL id="getComments"></liferay-portlet:resourceURL>';

					uri = Liferay.Util.addParams('<portlet:namespace />activitySetId=' + currentTarget.getAttribute('data-activitySetId'), uri) || uri;

					<%
						PortletURL likeURL = PortletURLFactoryUtil.create(request, "socialactivitymessageportlet_WAR_socialactivitymessageportlet", themeDisplay.getPlid(), PortletRequest.RESOURCE_PHASE);
						likeURL.setParameter("p_p_resource_id", "like");
						likeURL.setParameter("type", "2");

						PortletURL getLikesURL = PortletURLFactoryUtil.create(request, "socialactivitymessageportlet_WAR_socialactivitymessageportlet", themeDisplay.getPlid(), PortletRequest.RESOURCE_PHASE);
						getLikesURL.setParameter("p_p_resource_id", "getLikes");
						getLikesURL.setParameter("type", "2");
					%>

					A.io.request(
							uri,
							{
								after: {
									success: function(event, id, obj) {
										var responseData = this.get('responseData');

										if (responseData) {
											commentsList.empty();
											A.Array.each(
													responseData.comments,
													function(item, index) {
														item.original = item.body;
		                                                likesUrl = '<%=likeURL.toString()%>'+ "&_socialactivitymessageportlet_WAR_socialactivitymessageportlet_contentId="+encodeURIComponent(item.mbMessageIdOrMicroblogsEntryId);
		                                                likesUrl += "&_socialactivitymessageportlet_WAR_socialactivitymessageportlet_activityId="+encodeURIComponent(currentTarget.getAttribute('data-activitySetId'));
		                                                getLikesUrl = '<%=getLikesURL.toString()%>'+ "&_socialactivitymessageportlet_WAR_socialactivitymessageportlet_contentId="+encodeURIComponent(item.mbMessageIdOrMicroblogsEntryId);
														Liferay.SO.Activities.addNewComment(commentsList, item, likesUrl, getLikesUrl);
													}
											);

											commentsList.attr('loaded', 'true');
										}
									}
								},
								dataType: 'json'
							}
					);
				}

				commentsContainer.one('.comment-form').focus();
			},
			'.view-comments a'
	);

	socialActivities.delegate(
			'click',
			function(event) {
				if (confirm('<%= UnicodeLanguageUtil.get(pageContext,"are-you-sure-you-want-to-delete-the-selected-entry") %>')) {
					var currentTarget = event.currentTarget;

					var activityFooter = currentTarget.ancestor('.activity-footer');
					var commentEntry = currentTarget.ancestor('.comment-entry')
					var commentsContainer = currentTarget.ancestor('.comments-container');

					var form = commentsContainer.one('form');

					var cmdInput = form.one('#<portlet:namespace /><%= Constants.CMD %>');

					cmdInput.val('<%= Constants.DELETE %>');

					var mbMessageIdOrMicroblogsEntryId = currentTarget.attr('data-mbMessageIdOrMicroblogsEntryId');

					var mbMessageIdOrMicroblogsEntryIdInput = form.one('#<portlet:namespace />mbMessageIdOrMicroblogsEntryId');

					mbMessageIdOrMicroblogsEntryIdInput.val(mbMessageIdOrMicroblogsEntryId);

					A.io.request(
							form.attr('action'),
							{
								after: {
									success: function(event, id, obj) {
										var responseData = this.get('responseData');

										if (responseData.success) {
											commentEntry.remove();

											var viewComments = activityFooter.one('.view-comments a');

											var viewCommentsHtml = viewComments.html();

											var messagesCount = A.Lang.toInt(viewCommentsHtml) - 1;

											var commentText = '';

											if (messagesCount > 0) {
												commentText += messagesCount;
											}

											if (messagesCount > 1) {
												commentText += ' <%= UnicodeLanguageUtil.get(pageContext, "comments") %>';
											}
											else {
												commentText += ' <%= UnicodeLanguageUtil.get(pageContext, "comment") %>';
											}

											viewComments.html(commentText);
										}
									}
								},
								dataType: 'json',
								form: {
									id: form
								}
							}
					);
				}
			},
			'.comment-entry .delete-comment a'
	);

	socialActivities.delegate(
			'click',
			function(event) {
				var currentTarget = event.currentTarget;

				var mbMessageIdOrMicroblogsEntryId = currentTarget.getAttribute('data-mbMessageIdOrMicroblogsEntryId');

				var commentsContainer = currentTarget.ancestor('.comments-container');

				var editForm = commentsContainer.one('#<portlet:namespace />fm1' + mbMessageIdOrMicroblogsEntryId);

				var commentEntry = currentTarget.ancestor('.comment-entry');

				var message = commentEntry.one('.comment-body .message');
				var originalmessage = commentEntry.one('.comment-body .original-message');

				message.toggle();

				if (editForm) {
					editForm.toggle();
				}
				else {
					editForm = commentsContainer.one('form').cloneNode(true);

					editForm.show();

					editForm.attr(
							{
								id: '<portlet:namespace />fm1' + mbMessageIdOrMicroblogsEntryId,
								name: '<portlet:namespace />fm1' + mbMessageIdOrMicroblogsEntryId
							}
					);

					editForm.one('.comment-form').attr(
							{
								id: '<portlet:namespace />commentinput' + mbMessageIdOrMicroblogsEntryId
							}
					);

					editForm.one('.comment-cards').attr(
							{
								id: '<portlet:namespace />cards' + mbMessageIdOrMicroblogsEntryId
							}
					);

					editForm.one('.comment-alerts').attr(
							{
								id: '<portlet:namespace />commentalert' + mbMessageIdOrMicroblogsEntryId
							}
					);

					var userPortrait = editForm.one('.user-portrait');

					if (userPortrait) {
						userPortrait.remove();
					}


					var cmdInput = editForm.one('#<portlet:namespace /><%= Constants.CMD %>');

					cmdInput.val('<%= Constants.EDIT %>');

					var mbMessageIdOrMicroblogsEntryIdInput = editForm.one('#<portlet:namespace />mbMessageIdOrMicroblogsEntryId');

					mbMessageIdOrMicroblogsEntryIdInput.val(mbMessageIdOrMicroblogsEntryId);

					var commentBody = commentEntry.one('.comment-body');

					commentBody.append(editForm);

					Liferay['<portlet:namespace />-wysiwyg-skip'+mbMessageIdOrMicroblogsEntryId] = [];
					function getServiceSync() {
						var xhr = null;
						var args = parent.Liferay.Service.parseInvokeArgs(arguments);

						var syncIOConfig = {
							sync: true,
							on: {
								success: function(event, id, obj){
									xhr = obj;
								}
							}
						};

						args[1] = parent.AUI().merge(args[1], syncIOConfig);

						parent.Liferay.Service.invoke.apply(Liferay.Service, args);

						if(xhr){
							return eval('(' + xhr.responseText + ')');
						}
					};


					var handleCommentEditLinkInsert = function (event) {
						if ('autolinkAdd' === event.name || 'linkEdit' === event.data.constructor.key) {
							updateCommentCardsEdit(event.editor, mbMessageIdOrMicroblogsEntryId);
						}
					};
					var form = editForm;
					selections = [{
						name: 'link',
						buttons: ['linkEdit'],
						test: AlloyEditor.SelectionTest.link
					} , {
						name: 'text',
						buttons: ['removeFormat', 'bold', 'italic', 'underline', 'link'],
						test: AlloyEditor.SelectionTest.text
					}];
					var toolbars = {
						styles: {
							selections: selections,
							tabIndex: 1
						},
						add: {
							buttons: ['link'],
							tabIndex: 2
						}
					};
					noselections = [{
						name: 'text',
						buttons: [],
						test: AlloyEditor.SelectionTest.text
					}];
					var noToolbars = {
						styles: {
							selections: noselections,
							tabIndex: 1
						}
					};
					var editor = AlloyEditor.editable('<portlet:namespace />commentinput'+mbMessageIdOrMicroblogsEntryId, {
						toolbars: toolbars
					});
					if (typeof Liferay.SO.aeditors == 'undefined') {
						Liferay.SO.aeditors = [];
					}
					Liferay.SO.aeditors['commentinput'+mbMessageIdOrMicroblogsEntryId] = editor;
					var alertEditor = AlloyEditor.editable('<portlet:namespace />commentalert'+mbMessageIdOrMicroblogsEntryId, {
						toolbars: noToolbars
					});
					editor.get('nativeEditor').on('autolinkAdd', function (event) { handleCommentEditLinkInsert(event); });
					editor.get('nativeEditor').on('actionPerformed', function (event) { handleCommentEditLinkInsert(event); });

		var al = editForm.one('#<portlet:namespace />commentalert'+mbMessageIdOrMicroblogsEntryId);
		editor.get('nativeEditor').on('focus', function() {
		editor.get('srcNode').classList.add('in-use');
		if (al) {
		al.removeClass('hide');
		}
		});

					// TODO: Smileys
					editForm.on(
							'submit',
							function(event) {
								event.halt();
								var data = editor.get('nativeEditor').getData();
								var cards = A.one('#<portlet:namespace />cards'+mbMessageIdOrMicroblogsEntryId).getHTML();
		                        var alertsdata = alertEditor.get('nativeEditor').getData();
								editForm.one('#<portlet:namespace />body').set('value', data.replace(/<p>\s<\/p>/g, "") + cards);
		                        editForm.one('#<portlet:namespace />alerts').set('value', alertsdata);
								A.io.request(
										editForm.attr('action'),
										{
											after: {
												success: function(event, id, obj) {
													var responseData = this.get('responseData');

													if (responseData.success) {

														originalmessage.html(responseData.body);
														message.html(responseData.body);
														var postDate = commentEntry.one('.comment-info .post-date');
														postDate.html(responseData.modifiedDate);
														editForm.toggle();
														message.toggle();
														<%
                                                            PortletURL notificationURL = PortletURLFactoryUtil.create(request, "socialactivitymessageportlet_WAR_socialactivitymessageportlet", themeDisplay.getPlid(), PortletRequest.RESOURCE_PHASE);
                                                            notificationURL.setParameter("p_p_resource_id", "sendNotifications");
                                                            notificationURL.setParameter("type", "update");
                                                        %>
														var activity = currentTarget.ancestor('.activity-item');
														var activity_id = activity.get('id').split(/_/).pop();

														var notUri = '<%=notificationURL%>&_socialactivitymessageportlet_WAR_socialactivitymessageportlet_showSingle='+activity_id+'&_socialactivitymessageportlet_WAR_socialactivitymessageportlet_messageId='+mbMessageIdOrMicroblogsEntryId;
														var al = editForm.one('#<portlet:namespace />alerts');
														if (al) {
															notUri = notUri + "&_socialactivitymessageportlet_WAR_socialactivitymessageportlet_alerts="+encodeURIComponent(al.get('value'));
														}

														A.io.request(notUri, {
															dataType: 'json',
															cache: true,
															autoLoad: true,
															on: {
																success: function () {
																	var al = editForm.one('#<portlet:namespace />alerts');
																	if (al) {
																		al.set('value', '');
																	}
																},
																error: function() {
																	console.log('Error sending notifications')
																}
															}
														});
													}
												}
											},
											dataType: 'json',
											form: {
												id: editForm
											}
										}
								);
							}
					);
				}

				<%
                    PortletURL membersURL = PortletURLFactoryUtil.create(request, "socialactivitymessageportlet_WAR_socialactivitymessageportlet", themeDisplay.getPlid(), PortletRequest.RESOURCE_PHASE);
                    membersURL.setParameter("p_p_resource_id", "members");
                %>

				A.io.request('<%=membersURL%>', {
					dataType: 'json',
					cache: true,
					autoLoad: true,
					on: {
						success: function () {
							var members = this.get('responseData');
							members.menuItemTemplate = function (item) {
								return '<div class="user-portrait">' +
										'<span class="avatar">' +
										'<img alt="'+item.original.key+'" src="'+item.original.portrait + '">' +
										'</span>' +
										'</div>' +
										item.string.split('#')[0] +
										'<div class="job-title">'+item.original.title+'</div>';
							};
							members.selectTemplate = function (item) {
								return getServiceSync(
										'/socialactivitymessage-portlet.hioasocialactivity/get-mention',
										{
											username: item.original.value
										}
								);
							};
							members.lookup = function(person) {
								return person.key + '#' + person.value;
							};
							var tribute = new Tribute(members);
							var messageHtml = originalmessage.html();
							var bodyInput = editForm.one('#<portlet:namespace />commentinput' + mbMessageIdOrMicroblogsEntryId);
							var alertInput = editForm.one('#<portlet:namespace />commentalert' + mbMessageIdOrMicroblogsEntryId);
							Liferay.Service(
									'/socialactivitymessage-portlet.hioasocialactivity/strip-cards',
									{
										body: messageHtml
									},
									function(obj) {
										bodyInput.setHTML(obj);
										tribute.attach(bodyInput.getDOMNode());
										tribute.attach(alertInput.getDOMNode());
										updateCommentCardsEdit(Liferay.SO.aeditors['commentinput'+mbMessageIdOrMicroblogsEntryId].get('nativeEditor'), mbMessageIdOrMicroblogsEntryId);
									}
							);
						},
						error: function() {
							console.log('Error loading @mentions members')
						}
					}
				});
			},
			'.comment-entry .edit-comment a'
	);

	socialActivities.delegate(
			'click',
			function(event) {
				var currentTarget = event.currentTarget;

				var uri = '<portlet:renderURL windowState="<%= LiferayWindowState.POP_UP.toString() %>"><portlet:param name="mvcPath" value="/activities/repost_microblogs_entry.jsp" /><portlet:param name="mvcPath" value="/activities/repost_microblogs_entry.jsp" /><portlet:param name="redirect" value="<%= currentURL %>" /></portlet:renderURL>';

				uri = Liferay.Util.addParams('<portlet:namespace />microblogsEntryId=' + currentTarget.getAttribute('data-microblogsEntryId'), uri) || uri;

				Liferay.Util.openWindow(
						{
							cache: false,
							dialog: {
								align: Liferay.Util.Window.ALIGN_CENTER,
								modal: true,
								width: 400
							},
							id: '<portlet:namespace />Dialog',
							title: '<%= UnicodeLanguageUtil.get(pageContext, "repost") %>',
							uri: uri
						}
				);
			},
			'.repost a'
	);

	socialActivities.delegate(
			'click',
			function(event) {
				Liferay.SO.Activities.toggleEntry(event, '<portlet:namespace />');
			},
			'.toggle-entry'
	);

	Liferay.on(
			'microblogPosted',
			function(event) {
				Liferay.Portlet.refresh('#p_p_id<portlet:namespace />');
			}
	);

	Liferay.on(
			'sessionExpired',
			function(event) {
				var reload = function() {
					window.location.reload();
				};

				loadNewContent = reload;
			}
	);
	</aui:script>
