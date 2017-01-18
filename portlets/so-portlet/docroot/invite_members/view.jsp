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

<%@ include file="/init.jsp" %>

<%
	Group group = GroupLocalServiceUtil.getGroup(scopeGroupId);
	String theState = "collapsed";
	//if (renderRequest.getWindowState.equals(WindowState.MAXIMIZED)) {
	if ("true".equals(renderRequest.getParameter("displayImmediately"))) {
		theState = "open";
	}
%>

<c:choose>
	<c:when test="<%= group.isUser() %>">
		<liferay-ui:message key="this-application-will-only-function-when-placed-on-a-site-page" />
	</c:when>
	<c:when test="<%= GroupPermissionUtil.contains(permissionChecker, group.getGroupId(), ActionKeys.UPDATE) %>">
		<portlet:renderURL var="inviteURL" windowState="<%= LiferayWindowState.EXCLUSIVE.toString() %>">
			<portlet:param name="mvcPath" value="/invite_members/view_invite.jsp" />
		</portlet:renderURL>



		<liferay-ui:panel-container accordion="true" extended="false" cssClass="member-invite">
		<liferay-ui:panel title="invite-members-to-this-site" defaultState="<%=theState%>">
		<liferay-util:include page="/invite_members/view_invite.jsp" servletContext="<%= application %>" />


		<aui:script position="inline" use="aui-base,liferay-so-invite-members,liferay-util-window">
			AUI().ready('aui-base', 'aui-io-plugin-deprecated', 'liferay-so-invite-members', 'liferay-util-window', function(A) {
									new Liferay.SO.InviteMembers(
										{
											portletNamespace: '<portlet:namespace />'
										}
									);
			});
		</aui:script>
		</liferay-ui:panel>
			<div class="clearfix"></div>
		</liferay-ui:panel-container>

		<liferay-ui:panel-container accordion="true" extended="false" cssClass="previous-invites">
		<liferay-ui:panel title="previous-invites" defaultState="<%=theState%>">
			<table class="table table-bordered table-hover table-striped">
				<thead class="table-columns">
				<tr>
					<th class="table-first-header">
						<liferay-ui:message key="name-of-invitee" />
					</th>
					<th>
						<liferay-ui:message key="name-of-inviter" />
					</th>
					<th>
						<liferay-ui:message key="invite-role" />
					</th>
					<th>
						<liferay-ui:message key="invite-date" />
					</th>
					<th>
						<liferay-ui:message key="invite-status" />
					</th>
				</tr>
				</thead>
				<tbody>
				<%
					for (MemberRequest req : MemberRequestLocalServiceUtil.getRequests(group.getGroupId())) {
				%>
				<tr>
					<td class="table-cell first">
						<%
							long uid = req.getReceiverUserId();
							User rec = UserLocalServiceUtil.getUser(uid);
						%>
						<%=rec.getFullName()%><br>
					</td>
					<td class="table-cell">
						<%=req.getUserName()%><br>
					</td>
					<td class="table-cell">
						<%
							long rid = req.getInvitedRoleId();
							Role rer = RoleLocalServiceUtil.getRole(rid);
						%>
						<%=rer.getTitle(themeDisplay.getLocale())%><br>
					</td>
					<td class="table-cell">
						<%=dateFormatDate.format(req.getCreateDate())%><br>
					</td>
					<td class="table-cell">
						<span class="taglib-workflow-status">
							<span class="workflow-status">
								<c:choose>
									<c:when test="<%=req.getStatus()==1%>">
										<strong class="label workflow-status-approved label-success workflow-value"><liferay-ui:message key="invite-status-accepted" /></strong>
									</c:when>
									<c:when test="<%=req.getStatus()==2%>">
										<strong class="label workflow-status-approved label-important workflow-value"><liferay-ui:message key="invite-status-ignored" /></strong>
									</c:when>
									<c:otherwise>
										<strong class="label workflow-status-approved label-warning workflow-value"><liferay-ui:message key="invite-status-pending" /></strong>
									</c:otherwise>
								</c:choose>
							</span>
						</span>
					</td>
				</tr>
				<%
					}
				%>
				</tbody>
			</table>
		</liferay-ui:panel>
			<div class="clearfix"></div>
		</liferay-ui:panel-container>
	</c:when>
	<c:otherwise>
		<aui:script use="aui-base">
			var portlet = A.one('#p_p_id<portlet:namespace />');

			if (portlet) {
				portlet.hide();
			}
		</aui:script>
	</c:otherwise>
</c:choose>