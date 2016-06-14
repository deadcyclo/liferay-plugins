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

<%!
	public boolean isOwner(User user, long groupId, long companyId) throws SystemException, PortalException {
		Role ownerRole = RoleLocalServiceUtil.getRole(companyId, RoleConstants.SITE_OWNER);
		Role writeRole = RoleLocalServiceUtil.getRole(companyId, "Skrivetilgang Gruppe");
		Role commentRole = RoleLocalServiceUtil.getRole(companyId, "Lese og kommentere");
		List<UserGroupRole> ugr = UserGroupRoleLocalServiceUtil.getUserGroupRoles(user.getUserId(), groupId);
		for (UserGroupRole userGroupRole : ugr) {
			if (userGroupRole.getRole().equals(ownerRole) || userGroupRole.getRole().equals(writeRole)
					|| userGroupRole.getRole().equals(commentRole)) {
				return true;
			}
		}
		List<Role> rl =  RoleLocalServiceUtil.getUserGroupGroupRoles(user.getUserId(), groupId);
		if (rl.contains(ownerRole) || rl.contains(writeRole) || rl.contains(commentRole)) {
			return true;
		}
		return false;
	}
%>

<%
Group group = themeDisplay.getScopeGroup();

List<SocialActivitySet> results = null;

int count = 0;
int total = 0;

int start = ParamUtil.getInteger(request, "start");
int end = start + _DELTA;

	ServiceContext scontext = ServiceContextFactory.getInstance(request);

while ((count < _DELTA) && ((results == null) || !results.isEmpty())) {
	if (group.isUser()) {
		if (layout.isPrivateLayout()) {
			if (tabs1.equals("connections")) {
				results = SocialActivitySetLocalServiceUtil.getRelationActivitySets(group.getClassPK(), SocialRelationConstants.TYPE_BI_CONNECTION, start, end);
				total = SocialActivitySetLocalServiceUtil.getRelationActivitySetsCount(group.getClassPK(), SocialRelationConstants.TYPE_BI_CONNECTION);
			}
			else if (tabs1.equals("following")) {
				results = SocialActivitySetLocalServiceUtil.getRelationActivitySets(group.getClassPK(), SocialRelationConstants.TYPE_UNI_FOLLOWER, start, end);
				total = SocialActivitySetLocalServiceUtil.getRelationActivitySetsCount(group.getClassPK(), SocialRelationConstants.TYPE_UNI_FOLLOWER);
			}
			else if (tabs1.equals("me")) {
				results = SocialActivitySetLocalServiceUtil.getUserActivitySets(group.getClassPK(), start, end);
				total = SocialActivitySetLocalServiceUtil.getUserActivitySetsCount(group.getClassPK());
			}
			else if (tabs1.equals("my-sites")) {
				results = SocialActivitySetLocalServiceUtil.getUserGroupsActivitySets(group.getClassPK(), start, end);
				total = SocialActivitySetLocalServiceUtil.getUserGroupsActivitySetsCount(group.getClassPK());
			}
			else {
				results = SocialActivitySetLocalServiceUtil.getUserViewableActivitySets(group.getClassPK(), start, end);
				total = SocialActivitySetLocalServiceUtil.getUserViewableActivitySetsCount(group.getClassPK());
			}
		}
		else {
			results = SocialActivitySetLocalServiceUtil.getUserActivitySets(group.getClassPK(), start, end);
			total = SocialActivitySetLocalServiceUtil.getUserActivitySetsCount(group.getClassPK());
		}
	}
	else {
		if (count < 1 && start <1) {
			results = SocialActivitySetLocalServiceUtil.getGroupActivitySets(group.getGroupId(), -1, -1);
			List<SocialActivitySet> hioaresults = new ArrayList<SocialActivitySet>();
			scontext.setAttribute("showPinned", true);
			for (SocialActivitySet activitySet : results) {
				SocialActivityFeedEntry activityFeedEntry = SocialActivityInterpreterLocalServiceUtil.interpret("SO", activitySet, scontext);
				if (activityFeedEntry == null) {
					continue;
				}
				if (activityFeedEntry.getPortletId().equals("socialactivitymessageportlet_WAR_socialactivitymessageportlet")) {
					hioaresults.add(activitySet);
				}
			}
			if (hioaresults.size() > 0) {
			results = hioaresults;
			%><%@ include file="/activities/view_activity_sets_feed.jspf" %><%
			}
		}
		results = SocialActivitySetLocalServiceUtil.getGroupActivitySets(group.getGroupId(), start, end);
		total = SocialActivitySetLocalServiceUtil.getGroupActivitySetsCount(group.getGroupId());
	}
	scontext = ServiceContextFactory.getInstance(request);
%>

	<%@ include file="/activities/view_activity_sets_feed.jspf" %>

<%
	end = start + _DELTA;
}
%>

<aui:script>
	<portlet:namespace />start = <%= start %>;
</aui:script>

<c:if test="<%= (results.isEmpty()) %>">
	<div class="no-activities">
		<c:choose>
			<c:when test="<%= total == 0 %>">
				<liferay-ui:message key="there-are-no-activities" />
			</c:when>
			<c:otherwise>
				<liferay-ui:message key="there-are-no-more-activities" />
			</c:otherwise>
		</c:choose>
	</div>
</c:if>