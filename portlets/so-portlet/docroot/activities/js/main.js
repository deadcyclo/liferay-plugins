AUI.add(
	'liferay-so-scroll',
	function(A) {
		var Lang = A.Lang;

		var	isNumber = Lang.isNumber;
		var	isString = Lang.isString;

		var AVAILABLE = '-available';

		var BOTTOM = 'bottom';

		var DELAY = 'delay';

		var DOC_EL = A.config.doc.documentElement;

		var DOWN = 'down';

		var EDGE = '-edge';

		var EDGE_PROXIMITY = 'edgeProximity';

		var LAST_STATE = 'lastState';

		var MAX_COORDINATE = 'maxCoordinate';

		var SCROLL = 'scroll';

		var START = '-start';

		var Scroll = A.Component.create(
			{
				NAME: SCROLL,

				NS: SCROLL,

				ATTRS: {
					delay: {
						validator: isNumber,
						value: null
					},

					edgeProximity: {
						setter: function(val) {
							var value = 0;

							if (isNumber(val)) {
								value = val;
							}
							else if (isString(val)) {
								value = (Lang.toInt(val) / 100);
							}

							return value;
						},
						value: null
					},

					lastState: {
						value: {
							scrollTop: 0
						}
					},

					maxCoordinate: {
						value: null
					}
				},

				EXTENDS: A.Plugin.Base,

				prototype: {
					initializer: function(config) {
						var instance = this;

						var host = A.one(config.host);

						instance._host = host;

						instance._resetFn();

						host.on(SCROLL, A.bind('_onScroll', instance));

						instance._createResetTask();

						instance.after('delayChange', instance._createResetTask);
					},

					_createResetTask: function() {
						var instance = this;

						instance._resetTask = A.debounce('_resetFn', instance.get(DELAY), instance);
					},

					_onScroll: function(event) {
						var instance = this;

						var edgeProximity = instance.get(EDGE_PROXIMITY);
						var lastState = instance.get(LAST_STATE);
						var maxCoordinate = instance.get(MAX_COORDINATE);

						var edgeProximityY = edgeProximity;

						var maxCoordinateY = maxCoordinate.y;

						var host = instance._host;

						var scrollTop = host.get('scrollTop') || host.get('scrollY') || 0;

						if (edgeProximity % 1) {
							edgeProximityY *= maxCoordinateY;
						}

						var scrolledDown = (scrollTop > lastState.scrollTop);

						var availableScrollY = (scrollTop - maxCoordinateY);

						var state = {
							availableScrollY: availableScrollY,
							scrollTop: scrollTop,
							scrolledDown: scrolledDown
						};

						if (scrolledDown) {
							instance.fire(DOWN, state);

							if ((availableScrollY + edgeProximityY) >= 0) {
								instance.fire(BOTTOM + EDGE, state);
							}

							if (availableScrollY > 0) {
								instance.fire(DOWN + AVAILABLE, state);

								if (lastState.availableScrollY < 1) {
									instance.fire(DOWN + AVAILABLE + START, state);
								}
							}

							if (!lastState.scrolledDown) {
								instance.fire(DOWN + START, state);
							}
						}

						if ((availableScrollY > 0) || (scrollTop < 0)) {
							instance._resetFn();
						}

						instance.set(LAST_STATE, state);

						instance._resetTask();
					},

					_resetFn: function() {
						var instance = this;

						var lastState = instance.get(LAST_STATE);

						lastState.availableScrollY = 0;

						instance.set(LAST_STATE, lastState);

						var scrollY = instance._host._node.scrollHeight || DOC_EL.scrollHeight - DOC_EL.clientHeight;

						instance.set(
							MAX_COORDINATE,
							{
								y: scrollY
							}
						);
					}
				}
			}
		);

		Liferay.namespace('SO').Scroll = Scroll;
	},
	'',
	{
		requires: ['aui-base']
	}
);

AUI().use(
	'aui-base',
	'liferay-node',
	'transition',
	'handlebars',
	'aui-dialog',
	'aui-overlay-manager',
	function(A) {
		var TPL_COMMENT_ENTRY = '<div class="comment-entry" id="comment-entry-{mbMessageIdOrMicroblogsEntryId}">' +
			'<div class="user-portrait">' +
				'<span class="avatar">' +
					'<a href={userDisplayURL}>' +
						'<img alt={userName} src={userPortraitURL} />' +
					'</a>' +
				'</span>' +
			'</div>' +
			'<div class="comment-body">' +
				'<span class="user-name"><a href={userDisplayURL}>{userName}</a></span><p></p>' +
				'<div style="display:none;" class="original-message">{original}</div>' +
				'<span class="message">{body}</span>' +
			'</div>' +
			'<div class="comment-info">' +
				'<span class="post-date">{modifiedDate} </span>' +
				'<span class="edit-comment {commentControlsClass}">' +
					'<a data-mbMessageIdOrMicroblogsEntryId={mbMessageIdOrMicroblogsEntryId} href="javascript:;">' + Liferay.Language.get('edit') + '</a>' +
				'</span>' +
				'<span class="delete-comment {commentControlsClass}">' +
					'<a data-mbMessageIdOrMicroblogsEntryId={mbMessageIdOrMicroblogsEntryId} href="javascript:;">' + Liferay.Language.get('delete') + '</a>' +
				'</span>' +
			'</div>' +
			'<div class="likes-holder">' +
				'<div class="likes"></div>' +
				'<div class="like"><a href="javascript:;"><span class="icon icon-thumbs-up"></span></a></div>' +
			'</div>' +
		'</div>';

		A.Handlebars.registerHelper("sub", function(number) {
			return number-1;
		});
		A.Handlebars.registerHelper("json", function(input) {
			return JSON.stringify(input);
		});

		var TPL_LIKES_NONE = Liferay.Language.get('be-the-first');
		var TPL_LIKES_SINGLE = '<a target="_blank" href="https://hioa.no/tilsatt/{{likes.0.userName}}">{{likes.0.userFullName}}</a> '+Liferay.Language.get('likes-this');
		var TPL_LIKES_MANY = '<a target="_blank" href="https://hioa.no/tilsatt/{{random.userName}}">{{random.userFullName}}</a> '+Liferay.Language.get('and')+' <a href="#" class="other-likes" data-likes="{{json likes}}">{{sub count}} '+Liferay.Language.get('others')+'</a> '+Liferay.Language.get('like-this');
		var TPL_LIKES = '<div class="all-likes">{{#each this}}<div class="mention-card"><div class="user-portrait"><span class="avatar"><img alt="{{userFullName}}" src="{{portrait}}"></span></div>{{userFullName}}<div class="job-title">{{title}}</div><a target="_blank" href="https://hioa.no/tilsatt/{{userName}}"><span class="link-spanner"></span></a></a></div>{{/each}}</div>';
		var template_none = A.Handlebars.compile(TPL_LIKES_NONE);
		var template_single = A.Handlebars.compile(TPL_LIKES_SINGLE);
		var template_many = A.Handlebars.compile(TPL_LIKES_MANY);
		var template_likes = A.Handlebars.compile(TPL_LIKES);

		var Activities = {
			addNewComment: function(commentsList, responseData, likeUrl, getLikesUrl) {
				responseData.userDisplayURL = responseData.userDisplayURL || '';
				var entry = commentsList.append(A.Lang.sub(TPL_COMMENT_ENTRY, responseData)).one('#comment-entry-'+responseData.mbMessageIdOrMicroblogsEntryId);
				var likeLink = entry.one('.likes-holder .like a');

				handleResponse = function (responseData, entry) {
					var likeContent = entry.one('.likes-holder .likes');
					if (responseData.count == 0) {
						likeContent.setHTML(template_none(responseData));
					} else if (responseData.count == 1) {
						likeContent.setHTML(template_single(responseData));
					} else {
						likeContent.setHTML(template_many(responseData));
						likeContent.one('.other-likes').on('click', function(event) {
							event.preventDefault();
							event.stopPropagation();
							event.stopImmediatePropagation();
							var likes = JSON.parse(event.currentTarget.getAttribute('data-likes'));
							new A.Modal({
								centered: true,
								modal: false,
								bodyContent: template_likes(likes),
								zIndex: 1000,
								render: '#aui_popup_content',
							}).render();
							return false;
						});
					}
				};

				A.io.request(getLikesUrl, {
					dataType: 'json',
					cache: false,
					autoLoad: true,
					on: {
						success: function (obj) {
							var responseData = this.get('responseData');
							handleResponse(responseData, entry);
						},
						error: function() {
							console.log('Error getting likes');
						}
					}
				});

				likeLink.on('click', function(event) {
					A.io.request(likeUrl, {
						dataType: 'json',
						cache: false,
						autoLoad: true,
						on: {
							success: function (obj) {
								var responseData = this.get('responseData');
								handleResponse(responseData, entry);
							},
							error: function() {
								console.log('Error getting likes');
							}
						}
					});
				});
			},

			toggleEntry: function(event, portletNamespace) {
				var entryId = event.currentTarget.attr('data-entryId');

				var entry = A.byIdNS(portletNamespace, entryId);

				var body = entry.one('.grouped-activity-body');
				var bodyContainer = entry.one('.grouped-activity-body-container');
				var control = entry.one('.toggle-entry');
				var subentryHeight = entry.one('.activity-subentry').outerHeight();

				var minHeight = subentryHeight * 3;

				var bodyHeight = minHeight;

				var collapsed = entry.hasClass('toggler-content-collapsed');

				entry.toggleClass('toggler-content-collapsed', !collapsed);

				var viewText = '<i class="icon-expand-alt"></i><span> ' + Liferay.Language.get('view-more') + '</span>';

				if (collapsed) {
					bodyContainer.setStyles(
						{
							height: minHeight,
							maxHeight: 'none'
						}
					);

					bodyHeight = body.height();

					viewText = '<i class="icon-collapse-alt"></i><span> ' + Liferay.Language.get('view-less') + '</span>';
				}

				if (control) {
					control.html(viewText);
				}

				bodyContainer.transition(
					{
						duration: 0.5,
						easing: 'ease-in-out',
						height: bodyHeight + 'px'
					}
				);
			}
		};

		Liferay.namespace('SO').Activities = Activities;
	}
);