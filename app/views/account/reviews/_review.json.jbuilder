json.extract! review, :id, :rate, :moderated
json.content review.content
json.date Russian::strftime(review.created_at, "%d %B %H:%M")

json.reviewer_name review.reviewer.name
json.reviewer_url review.reviewer.url
json.reviewer_avatar review.reviewer.avatar_url(:preview)