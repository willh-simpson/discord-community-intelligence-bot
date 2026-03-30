from datetime import timedelta

from django.utils import timezone
from django.db.models import Count, Avg
from rest_framework.decorators import api_view
from rest_framework.response import Response
from .models import MessageEvent

@api_view(['GET'])
def health(request):
    return Response(
        { "status": "ok" },
        status=200
    )


@api_view(['GET'])
def insights(request):
    window_minutes = int(request.GET.get("window", 5))

    since = timezone.now() - timedelta(minutes=window_minutes)
    qs = MessageEvent.objects.filter(timestamp__gte=since)

    top_channels = (
        qs.values("channel_id")
        .annotate(count=Count("id"))
        .order_by("-count")[:5]
    )

    top_users = (
        qs.values("user_id")
        .annotate(count=Count("id"))
        .order_by("-count")[:5]
    )

    total_messages = qs.count()
    average_per_minute = total_messages / max(window_minutes, 1)
    average_length = qs.aggregate(avg=Avg("content_length"))["avg"] or 0

    return Response({
        "window_minutes": window_minutes,
        "top_channels": list(top_channels),
        "top_users": list(top_users),
        "average_messages_per_minute": average_per_minute,
        "average_message_length": average_length,
        "total_messages": total_messages
    })


@api_view(['POST'])
def extract_features(request):
    # payload looks like -> { "messages": [...], "users": [...] }
    messages = request.data.get("messages", [])
    users = request.data.get("users", [])

    # messages per user + average message length
    user_message_counts = {user: 0 for user in users}
    total_length = 0

    for msg in messages:
        user_message_counts[msg['user_id']] += 1
        total_length += len(msg.get('content', ''))
    
    average_length = total_length / max(len(messages), 1)

    return Response({
        "user_message_counts": user_message_counts,
        "average_message_length": average_length
    })


@api_view(['POST'])
def engagement_score(request):
    user_message_counts = request.data.get("user_message_counts", {})

    scores = {user: count ** 0.5 for user, count in user_message_counts.items()}

    return Response({
        "engagement_scores": scores
    })


@api_view(['POST'])
def ingest(request):
    events = request.data.get("events", [])
    objs = []

    for e in events:
        objs.append(
            MessageEvent(
                user_id=e["user_id"],
                channel_id=e["channel_id"],
                content_length=len(e.get("content", "")),
                timestamp=e["timestamp"],
            )
        )
    
    MessageEvent.objects.bulk_create(objs)

    return Response({"status": "ok"})
