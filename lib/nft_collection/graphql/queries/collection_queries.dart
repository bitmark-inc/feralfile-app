const collectionQuery = r'''
    query GetCollections($creators: [String!]! = [], $offset: Int64! = 0, $size: Int64! = 100) {
  collections(
    creators: $creators,
    offset: $offset,
    size: $size,
  ) {
    id
    description
    externalID
    imageURL
    items
    name
    creators
    published
    source
    createdAt
  }
}
''';
