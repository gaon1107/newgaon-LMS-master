import React, { useState, useEffect } from 'react'
import {
  Box,
  Typography,
  Card,
  CardContent,
  Table,
  TableBody,
  TableCell,
  TableContainer,
  TableHead,
  TableRow,
  Chip,
  Button,
  Grid,
  TextField,
  FormControl,
  InputLabel,
  Select,
  MenuItem,
  IconButton,
  Tooltip,
  Paper,
  Divider
} from '@mui/material'
import {
  Payment as PaymentIcon,
  FileDownload as DownloadIcon,
  Search as SearchIcon,
  Receipt as ReceiptIcon,
  CreditCard as CardIcon,
  AccountBalance as BankIcon,
  Phone as PhoneIcon
} from '@mui/icons-material'

const PaymentPage = () => {
  const [payments, setPayments] = useState([])
  const [loading, setLoading] = useState(true)
  const [searchTerm, setSearchTerm] = useState('')
  const [statusFilter, setStatusFilter] = useState('all')
  const [dateRange, setDateRange] = useState({ start: '', end: '' })

  // 임시 결제 데이터
  const mockPayments = [
    {
      id: 'PAY001',
      date: '2024-12-15',
      product: '가온 출결 시스템 Pro',
      period: '1년',
      amount: 480000,
      method: 'card',
      methodDetail: '신한카드 1234',
      status: 'completed',
      receiptUrl: '#',
      description: '연간 라이선스'
    },
    {
      id: 'PAY002',
      date: '2024-11-20',
      product: 'SMS 서비스 패키지',
      period: '월간',
      amount: 50000,
      method: 'bank',
      methodDetail: '국민은행 자동이체',
      status: 'completed',
      receiptUrl: '#',
      description: '월 5,000건 SMS'
    },
    {
      id: 'PAY003',
      date: '2024-10-25',
      product: '추가 저장공간',
      period: '월간',
      amount: 30000,
      method: 'phone',
      methodDetail: '휴대폰 결제',
      status: 'completed',
      receiptUrl: '#',
      description: '10GB 추가 저장공간'
    },
    {
      id: 'PAY004',
      date: '2024-10-01',
      product: '가온 출결 시스템 Pro',
      period: '월간',
      amount: 50000,
      method: 'card',
      methodDetail: '삼성카드 5678',
      status: 'failed',
      receiptUrl: null,
      description: '월간 라이선스'
    },
    {
      id: 'PAY005',
      date: '2024-09-15',
      product: 'SMS 서비스 패키지',
      period: '월간',
      amount: 50000,
      method: 'bank',
      methodDetail: '우리은행 자동이체',
      status: 'pending',
      receiptUrl: null,
      description: '월 5,000건 SMS'
    }
  ]

  useEffect(() => {
    // 결제 내역 로드
    const loadPayments = async () => {
      setLoading(true)
      try {
        // API 호출 대신 임시 데이터 사용
        await new Promise(resolve => setTimeout(resolve, 1000))
        setPayments(mockPayments)
      } catch (error) {
        console.error('결제 내역 로드 실패:', error)
      } finally {
        setLoading(false)
      }
    }

    loadPayments()
  }, [])

  const getStatusColor = (status) => {
    switch (status) {
      case 'completed': return 'success'
      case 'pending': return 'warning'
      case 'failed': return 'error'
      default: return 'default'
    }
  }

  const getStatusText = (status) => {
    switch (status) {
      case 'completed': return '결제완료'
      case 'pending': return '결제대기'
      case 'failed': return '결제실패'
      default: return '알 수 없음'
    }
  }

  const getMethodIcon = (method) => {
    switch (method) {
      case 'card': return <CardIcon />
      case 'bank': return <BankIcon />
      case 'phone': return <PhoneIcon />
      default: return <PaymentIcon />
    }
  }

  const getMethodText = (method) => {
    switch (method) {
      case 'card': return '신용카드'
      case 'bank': return '계좌이체'
      case 'phone': return '휴대폰결제'
      default: return '기타'
    }
  }

  const filteredPayments = payments.filter(payment => {
    const matchesSearch = payment.product.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         payment.id.toLowerCase().includes(searchTerm.toLowerCase())
    const matchesStatus = statusFilter === 'all' || payment.status === statusFilter

    return matchesSearch && matchesStatus
  })

  const handleDownloadReceipt = (payment) => {
    // 영수증 다운로드 로직
    console.log('영수증 다운로드:', payment.id)
    // 실제로는 PDF 생성 또는 API 호출
    alert(`${payment.id} 영수증을 다운로드합니다.`)
  }

  const totalAmount = filteredPayments
    .filter(p => p.status === 'completed')
    .reduce((sum, payment) => sum + payment.amount, 0)

  return (
    <Box>
      <Typography variant="h4" component="h1" gutterBottom>
        <PaymentIcon sx={{ mr: 1, verticalAlign: 'middle' }} />
        결제 내역
      </Typography>

      {/* 통계 요약 */}
      <Grid container spacing={3} sx={{ mb: 3 }}>
        <Grid item xs={12} sm={6} md={3}>
          <Paper sx={{ p: 2, textAlign: 'center' }}>
            <Typography variant="h6" color="primary">
              {filteredPayments.length}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              총 결제건수
            </Typography>
          </Paper>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Paper sx={{ p: 2, textAlign: 'center' }}>
            <Typography variant="h6" color="success.main">
              {filteredPayments.filter(p => p.status === 'completed').length}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              결제완료
            </Typography>
          </Paper>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Paper sx={{ p: 2, textAlign: 'center' }}>
            <Typography variant="h6" color="warning.main">
              {filteredPayments.filter(p => p.status === 'pending').length}
            </Typography>
            <Typography variant="body2" color="text.secondary">
              결제대기
            </Typography>
          </Paper>
        </Grid>
        <Grid item xs={12} sm={6} md={3}>
          <Paper sx={{ p: 2, textAlign: 'center' }}>
            <Typography variant="h6" color="primary">
              {totalAmount.toLocaleString()}원
            </Typography>
            <Typography variant="body2" color="text.secondary">
              총 결제금액
            </Typography>
          </Paper>
        </Grid>
      </Grid>

      {/* 검색 및 필터 */}
      <Card sx={{ mb: 3 }}>
        <CardContent>
          <Grid container spacing={2} alignItems="center">
            <Grid item xs={12} sm={4}>
              <TextField
                fullWidth
                label="검색"
                placeholder="상품명 또는 주문번호 검색"
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                InputProps={{
                  startAdornment: <SearchIcon sx={{ mr: 1, color: 'text.secondary' }} />
                }}
              />
            </Grid>
            <Grid item xs={12} sm={3}>
              <FormControl fullWidth>
                <InputLabel>결제상태</InputLabel>
                <Select
                  value={statusFilter}
                  onChange={(e) => setStatusFilter(e.target.value)}
                  label="결제상태"
                >
                  <MenuItem value="all">전체</MenuItem>
                  <MenuItem value="completed">결제완료</MenuItem>
                  <MenuItem value="pending">결제대기</MenuItem>
                  <MenuItem value="failed">결제실패</MenuItem>
                </Select>
              </FormControl>
            </Grid>
            <Grid item xs={12} sm={2.5}>
              <TextField
                fullWidth
                label="시작일"
                type="date"
                value={dateRange.start}
                onChange={(e) => setDateRange(prev => ({ ...prev, start: e.target.value }))}
                InputLabelProps={{ shrink: true }}
              />
            </Grid>
            <Grid item xs={12} sm={2.5}>
              <TextField
                fullWidth
                label="종료일"
                type="date"
                value={dateRange.end}
                onChange={(e) => setDateRange(prev => ({ ...prev, end: e.target.value }))}
                InputLabelProps={{ shrink: true }}
              />
            </Grid>
          </Grid>
        </CardContent>
      </Card>

      {/* 결제 내역 테이블 */}
      <Card>
        <CardContent>
          <Typography variant="h6" gutterBottom>
            결제 내역 목록
          </Typography>

          <TableContainer>
            <Table>
              <TableHead>
                <TableRow>
                  <TableCell>주문번호</TableCell>
                  <TableCell>결제일</TableCell>
                  <TableCell>상품명</TableCell>
                  <TableCell>결제방법</TableCell>
                  <TableCell align="right">금액</TableCell>
                  <TableCell>상태</TableCell>
                  <TableCell align="center">영수증</TableCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {loading ? (
                  <TableRow>
                    <TableCell colSpan={7} align="center">
                      로딩 중...
                    </TableCell>
                  </TableRow>
                ) : filteredPayments.length === 0 ? (
                  <TableRow>
                    <TableCell colSpan={7} align="center">
                      검색 결과가 없습니다.
                    </TableCell>
                  </TableRow>
                ) : (
                  filteredPayments.map((payment) => (
                    <TableRow key={payment.id} hover>
                      <TableCell>
                        <Typography variant="body2" fontWeight="bold">
                          {payment.id}
                        </Typography>
                      </TableCell>
                      <TableCell>{payment.date}</TableCell>
                      <TableCell>
                        <Typography variant="body2">
                          {payment.product}
                        </Typography>
                        <Typography variant="caption" color="text.secondary">
                          {payment.description} ({payment.period})
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <Box sx={{ display: 'flex', alignItems: 'center' }}>
                          {getMethodIcon(payment.method)}
                          <Box sx={{ ml: 1 }}>
                            <Typography variant="body2">
                              {getMethodText(payment.method)}
                            </Typography>
                            <Typography variant="caption" color="text.secondary">
                              {payment.methodDetail}
                            </Typography>
                          </Box>
                        </Box>
                      </TableCell>
                      <TableCell align="right">
                        <Typography variant="body2" fontWeight="bold">
                          {payment.amount.toLocaleString()}원
                        </Typography>
                      </TableCell>
                      <TableCell>
                        <Chip
                          label={getStatusText(payment.status)}
                          color={getStatusColor(payment.status)}
                          size="small"
                        />
                      </TableCell>
                      <TableCell align="center">
                        {payment.receiptUrl ? (
                          <Tooltip title="영수증 다운로드">
                            <IconButton
                              size="small"
                              onClick={() => handleDownloadReceipt(payment)}
                            >
                              <DownloadIcon />
                            </IconButton>
                          </Tooltip>
                        ) : (
                          <Typography variant="caption" color="text.secondary">
                            -
                          </Typography>
                        )}
                      </TableCell>
                    </TableRow>
                  ))
                )}
              </TableBody>
            </Table>
          </TableContainer>
        </CardContent>
      </Card>

      {/* 결제 안내 */}
      <Paper sx={{ p: 3, mt: 3, bgcolor: 'background.default' }}>
        <Typography variant="h6" gutterBottom>
          <ReceiptIcon sx={{ mr: 1, verticalAlign: 'middle' }} />
          결제 안내
        </Typography>
        <Typography variant="body2" paragraph>
          • 결제 완료 후 영수증은 이메일로도 발송됩니다.
        </Typography>
        <Typography variant="body2" paragraph>
          • 자동결제 설정 시 매월 결제일에 자동으로 결제됩니다.
        </Typography>
        <Typography variant="body2" paragraph>
          • 결제 관련 문의사항은 고객센터로 연락해주세요.
        </Typography>
        <Typography variant="body2">
          • 환불 및 취소는 결제 후 7일 이내에만 가능합니다.
        </Typography>
      </Paper>
    </Box>
  )
}

export default PaymentPage